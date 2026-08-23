---
name: sandcastle-setup
description: Set up Sandcastle in a project with Pi agents, Podman sandboxes, corporate certificate handling, issue-tracker authentication, reusable prompts, resource limits, and validation. Invoke when a user asks to initialise Sandcastle, configure sandcastle init, patch a generated Sandcastle setup, switch its issue tracker to Gitea/Forgejo or GitLab, or make the setup repeatable.
---

# Sandcastle setup

Use this skill to turn a fresh `sandcastle init` scaffold into the user's preferred repeatable setup. Work in phases. The first phase is manual and requires the user to run interactive commands. Stop at the manual gate. Take over only after the user confirms those steps are complete.

## Operating contract

- Use the project's existing Git repository. Do not initialise a second repository inside the project.
- Inspect `git status`, the current branch, and repository instructions before editing.
- Preserve existing project conventions. Read `AGENTS.md`, `CONTEXT.md`, and relevant ADRs when present.
- Never print, log, commit, or place tokens in command output. Redact credentials as `<REDACTED>`.
- Do not pin the Pi package version. Install the current `@earendil-works/pi-coding-agent` package in the sandbox image.
- Use the gated workflow in `references/workflow-template/`: the merger integrates verified issue branches into the target branch and the script closes the issue only after mechanical postconditions pass. Do not replace this with an unguarded automatic merge.
- Use `tea` for Gitea/Forgejo Issues and `glab` for GitLab Issues. Do not leave mixed GitHub and alternative-tracker commands in prompts or image setup.
- If a required host binary or certificate is missing, stop and guide the user to install or provide it. Do not invent a workaround.

## Phase 0 — Manual setup gate

Present this checklist and ask the user to perform it. Do not run these interactive steps on the user's behalf:

1. Install Sandcastle:

   ```bash
   npm install --save-dev @ai-hero/sandcastle
   ```

2. Initialise the scaffold:

   ```bash
   npx @ai-hero/sandcastle init
   ```

   Select these answers:

   - Install dependencies: **y**.
   - Agent: **Pi**.
   - Sandbox provider: **Podman**.
   - Issue tracker: **GitHub**.
   - Template: **blank** (the setup will install the repository's explicit workflow rather than extend a vendor workflow implicitly).
   - Create the `Sandcastle` label: **Yes**. The selected tracker adapter will preserve this label contract.
   - Install `zod` now: **Yes**.
   - Build the default image now: **No**. The generated `Containerfile` needs the corporate-certificate and Pi patches first.

3. Copy the generated environment template:

   ```bash
   cp .sandcastle/.env.example .sandcastle/.env
   ```

4. Ask the user which issue tracker to retain:

   - **GitHub** — keep the generated GitHub wiring. Ask the user to run `gh auth token` and copy the token into `.sandcastle/.env` as `GH_TOKEN=<REDACTED>`.
   - **Gitea / Forgejo** — the agent will take over and replace the GitHub wiring before guiding Gitea authentication.
   - **GitLab** — the agent will take over and replace the GitHub wiring before guiding GitLab authentication.

Do not proceed until the user confirms the commands completed and answers the tracker question.

After confirmation, install the explicit workflow from this skill instead of hand-editing the generated template:

```bash
cp <sandcastle-setup-skill>/references/workflow-template/main.mts .sandcastle/main.mts
cp <sandcastle-setup-skill>/references/workflow-template/scrun ./scrun
cp <sandcastle-setup-skill>/references/workflow-template/*-prompt.md .sandcastle/
cp <sandcastle-setup-skill>/references/workflow-template/Containerfile.github .sandcastle/Containerfile
cp <sandcastle-setup-skill>/references/workflow-template/sandcastle.gitignore .sandcastle/.gitignore
cp <sandcastle-setup-skill>/references/workflow-template/scbuild ./scbuild
chmod u+x scrun scbuild
```

Replace `<sandcastle-setup-skill>` with the absolute skill directory shown by the skill loader. The copied template is the GitHub implementation. For Gitea/Forgejo or GitLab, apply the tracker adapter in Phase 4 to the copied files; do not mix tracker command sets.

## Phase 1 — Inspect and establish preferences

After the manual gate:

1. Verify that the project is a Git repository and that the generated files exist:

   - `.sandcastle/Containerfile`
   - `.sandcastle/main.mts`
   - `.sandcastle/.env.example`
   - `.sandcastle/.gitignore`
   - The planner, implementer, reviewer, and merger prompts.

2. Check the project's `package.json` and package manager. Preserve the generated Sandcastle dependency and `zod` dependency.

3. Check the host prerequisites:

   ```bash
   command -v node
   command -v npm
   command -v podman
   pi --version
   ```

4. Inspect the runtime capacity before selecting a concurrency limit:

   ```bash
   nproc
   free -h
   cat /proc/loadavg
   df -hT /
   podman info --format 'cpus={{.Host.CPUs}} mem={{.Host.MemTotal}} rootless={{.Host.Security.Rootless}}'
   podman stats --no-stream
   ```

   Treat CPU count and Podman memory ceiling as stable or slowly changing. Treat available memory, load, swap use, existing containers, test/build spikes, and network/API capacity as runtime variables. Start with `MAX_CONCURRENT_ISSUES = 8` only when runtime observations support it; otherwise choose a lower value and record why.

5. Use the copied `scrun` interface to select Pi preferences. Its defaults are:

   | Role | Model | Thinking |
   |---|---|---|
   | Planner | `gpt-5.6-luna` | `high` |
   | Implementer | `gpt-5.6-luna` | `medium` |
   | Reviewer | `gpt-5.6-terra` | `off` |
   | Merger | `gpt-5.6-terra` | `off` |

   `./scrun --help` shows all named model and thinking options. The runner validates each selected model and its thinking level against `~/.pi/agent/models-store.json`, including model-specific unsupported levels, before launching an agent. If a default or supplied model is unavailable, stop and ask which model to use. Do not silently substitute models.

## Phase 2 — Patch the Podman image

Read the project's corporate-certificate instructions if available. Apply the pattern in `references/podman-corporate-certificates.md`.

### Corporate certificate

The host certificate is supplied through `$NODE_EXTRA_CA_CERTS`. If that variable is set and points to a readable file:

```bash
cp "$NODE_EXTRA_CA_CERTS" .sandcastle/extra-certs.crt
```

Add the file to `.sandcastle/.gitignore`. In `.sandcastle/Containerfile`, before network-dependent `apt`, `curl`, and npm operations, add:

```dockerfile
COPY extra-certs.crt /usr/local/share/ca-certificates/extra-certs.crt
RUN update-ca-certificates

ENV NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt \
    NODE_USE_SYSTEM_CA=1
```

Do not replace Debian's complete CA bundle with only the corporate certificate. If `$NODE_EXTRA_CA_CERTS` is unavailable, stop and ask the user to provide the certificate or install the required trust configuration.

### Pi distribution and issue-tracker CLI

Replace the generated Pi installation:

```dockerfile
RUN npm install -g @mariozechner/pi-coding-agent
```

with the unpinned user-preferred distribution:

```dockerfile
RUN npm install -g @earendil-works/pi-coding-agent
```

Retain `git`, `curl`, and `jq` in the base dependencies. For Gitea/Forgejo or GitLab, add the relevant CLI installation described in the issue-tracker section below.

Build only after all image patches:

```bash
./scbuild
```

## Phase 3 — Install the explicit Pi orchestration and prompts

The copied files in `references/workflow-template/` are the source of truth for the workflow. Copy them first. Read `references/patch-snippets.md` only for optional mounts, approval wrappers, and project-specific adaptations. Do not reconstruct the orchestrator from prose or combine it with the vendor's parallel-planner workflow.

The workflow is:

1. The planner receives the complete mechanically acquired candidate set and emits exact issue IDs, titles, and deterministic branches.
2. The script validates planner output and runs issue pipelines in batches of up to eight.
3. Each issue pipeline uses one explicit branch/worktree shared by implementer and reviewer. It runs up to four implement⇄review rounds, with 64 implementer and 16 reviewer iterations per round.
4. The reviewer is a gate. Approval requires the review marker, the completion signal, and `READY-FOR-MERGER-AGENT` as the final issue comment.
5. The merger processes approved branches sequentially, integrates each branch, resolves conflicts within its budget, verifies the integrated target branch, posts a merge receipt, and only then permits script-owned issue closure.
6. The script owns all bookkeeping, labels, branch-integrity checks, failure counts, and circuit breakers. The merger may close only after its per-branch verification receipt; the script remains the final postcondition authority. Agents do not push branches or apply `ready-for-human`.

The exact marker formats, prompts, model interface, and postcondition code are in the template files. Preserve their run ID and round substitutions when adapting tracker commands.

### Pi authentication, model catalogue, skills, and extensions

Every new project should replicate the host Pi configuration used by this setup. In `piSandbox()`, add these mounts:

| Host path | Container path | Mode | Purpose |
|---|---|---|---|
| `~/.pi/agent/auth.json` | `/home/agent/.pi/agent/auth.json` | read-write | Pi credentials and provider lock file |
| `~/.pi/agent/models-store.json` | `/home/agent/.pi/agent/models-store.json` | read-only | Pi model catalogue |
| `~/.agents/skills/<name>` | `/home/agent/.pi/agent/skills/<name>` | read-only | Host Pi skills |
| `~/.pi/agent/git/<host>/<owner>/<extension>` | matching `/home/agent/.pi/agent/git/...` path | read-only | Host Pi extension source |

Use this standard mount shape:

```ts
const PI_SKILLS = [
  "code-review",
  "codebase-design",
  "diagnosing-bugs",
  "implement",
  "improve-codebase-architecture",
  "resolving-merge-conflicts",
  "tdd",
  "triage",
];

const PI_EXTENSIONS = [
  {
    hostPath: "~/.pi/agent/git/github.com/algal/pi-openai-server-compaction",
    sandboxPath:
      "/home/agent/.pi/agent/git/github.com/algal/pi-openai-server-compaction",
  },
];

const piSandbox = () =>
  podman({
    mounts: [
      {
        hostPath: "~/.pi/agent/auth.json",
        sandboxPath: "/home/agent/.pi/agent/auth.json",
        readonly: false,
      },
      {
        hostPath: "~/.pi/agent/models-store.json",
        sandboxPath: "/home/agent/.pi/agent/models-store.json",
        readonly: true,
      },
      ...PI_SKILLS.map((skill) => ({
        hostPath: `~/.agents/skills/${skill}`,
        sandboxPath: `/home/agent/.pi/agent/skills/${skill}`,
        readonly: true,
      })),
      ...PI_EXTENSIONS.map((extension) => ({
        ...extension,
        readonly: true,
      })),
    ],
  });
```

Before adding a mount, verify that the host path exists. Keep the standard skills and extensions that are available; add project-required skills or extensions to the arrays. Do not mount the entire host Pi directory: mount only the required credentials, model catalogue, skills, and extension sources.

Pi creates a sibling lock file while refreshing provider availability. A read-only `auth.json` mount can make the provider appear to have no models. The auth mount must therefore be read-write; never log its contents. The model catalogue, skills, and extension source remain read-only.

The standard role mapping is:

- Planner: `triage`, `codebase-design`.
- Implementer: `implement`, `tdd`, and diagnosis/architecture/conflict skills when relevant.
- Reviewer: `code-review`, `codebase-design`, architecture and test skills when relevant.
- Merger: conflict-resolution and test skills when relevant.

Prompts must tell agents to read `CONTEXT.md` and relevant ADRs before changing domain concepts or architecture.

### Optional Pi approval wrapper

Do **not** create `bin/pi-approved` or a custom Pi provider by default. Native `sandcastle.pi(model)` is the standard provider.

Add the wrapper only when the project is itself developing a Pi extension or has an explicit requirement to trust project-local Pi files through `pi --approve`. In that optional case, create `bin/pi-approved` with executable mode:

```bash
#!/usr/bin/env bash
set -euo pipefail
exec pi --approve "$@"
```

Then create a custom provider wrapper that delegates parsing and session storage to `sandcastle.pi(model)` but replaces the executable with `bin/pi-approved` for print and interactive commands. Add a focused test for that wrapper. Pi's `--approve` trusts project-local files; it is not unrestricted tool permission bypass.
### Resource limit

The copied template already implements bounded batches with `MAX_CONCURRENT_ISSUES = 8`. Do not replace it with an unbounded `Promise.all` fan-out. The generated parallel planner usually uses:

```ts
await Promise.allSettled(issues.map(runIssuePipeline));
```

That starts every planned issue immediately. Add:

```ts
const MAX_CONCURRENT_ISSUES = 8;
```

Then process issues in bounded batches:

```ts
const settled = [];

for (
  let offset = 0;
  offset < issues.length;
  offset += MAX_CONCURRENT_ISSUES
) {
  const batch = issues.slice(offset, offset + MAX_CONCURRENT_ISSUES);
  const batchResults = await Promise.allSettled(
    batch.map(runIssuePipeline),
  );
  settled.push(...batchResults);
}
```

Keep the existing issue-pipeline callback and result handling. Implementer and reviewer remain sequential within one pipeline. Planner runs once before the batches and merger once after them in each outer iteration. A worker pool is a later optimisation if batches must refill slots immediately when individual pipelines finish.

If the project needs per-container CPU control, use the provider option supported by the installed Sandcastle version, for example:

```ts
podman({ cpus: 1.5 })
```

Do not assume a memory option exists. The global concurrency limit is the primary memory control unless the installed provider exposes a memory limit.

### Branch and review workflow

Use explicit named issue branches: `sandcastle/issue-<ID>`. The implementer and reviewer share that issue worktree. Planner and merger calls use the target integration branch. The merger handles one approved branch at a time and the script proves ancestry before closing the issue.

The reviewer gate is not a request for an atomic or single-finding review. The reviewer must report every established blocking finding in one comment, using the prescribed finding format. Human scope decisions remain in issue comments; prose is not treated as a machine gate.

If a ticket exhausts the four-round implement⇄review budget, or the merger failure ledger reaches its threshold, the script adds `ready-for-human`, removes `Sandcastle`, and leaves the issue open. Removing `Sandcastle` is the planner circuit breaker. A stale open issue whose final comment is already `READY-FOR-MERGER-AGENT` is not planner work; reconcile it by verifying the branch and merging manually, or explicitly requeue it by superseding the token and restoring the label.

### Prompt and model validation

Check all generated prompt files for:

- Correct issue-tracker commands.
- Correct label name and filtering.
- Correct view, comment, close, and merge instructions.
- No stale GitHub commands after a Gitea or GitLab migration.
- Required skills and project-context instructions.

## Phase 4 — Issue-tracker migration

Run this phase only if the user selected Gitea/Forgejo or GitLab after the manual gate.

### Common migration rules

Replace the issue-tracker commands and prose in:

- `.sandcastle/.env.example`
- `.sandcastle/Containerfile`
- `plan-prompt.md`
- `implement-prompt.md`
- `merge-prompt.md`
- Any other generated prompt containing GitHub commands.
- `.sandcastle/main.mts` hooks used for tracker authentication or label creation.

Keep the same domain contract: list open issues with the `Sandcastle` label, view issue details and comments, comment on completion, and close completed issues. Preserve JSON normalisation expected by the planner.

Test the host CLI before changing the setup:

```bash
command -v tea && tea --version
command -v glab && glab --version
```

Only the selected tracker is mandatory. If its host CLI is missing, stop and guide the user to install it from the official documentation. After the user installs it, rerun the test. The container CLI is mandatory too; install it in `Containerfile`, rebuild, and verify it inside the image:

```bash
podman run --rm --entrypoint tea <image-name> --version
podman run --rm --entrypoint glab <image-name> --version
```

Use only the command for the selected tracker.

### Gitea / Forgejo with `tea`

Host prerequisite and authentication:

1. Test `tea` on the host.
2. If missing, guide the user to install the official binary or package from [tea installation documentation](https://gitea.com/gitea/tea#installation), then stop until they confirm it works.
3. Ask the user for the Gitea/Forgejo server URL and a personal access token with the required issue read/write permissions.
4. Add these variables to `.sandcastle/.env` without printing the token:

   ```dotenv
   GITEA_SERVER_URL=https://gitea.example.com
   GITEA_ACCESS_TOKEN=<REDACTED>
   ```

5. Guide the user to authenticate the host CLI, for example:

   ```bash
   tea login add --name sandcastle --url "$GITEA_SERVER_URL" --token "$GITEA_ACCESS_TOKEN"
   tea login default sandcastle
   tea whoami
   ```

   Use the official interactive flow if the local `tea` version differs. The token should be supplied through a protected environment or prompt, not committed.

Container installation pattern, based on the reference implementation in [Sandcastle PR #512](https://github.com/mattpocock/sandcastle/pull/512/changes):

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

The reference implementation's generated runtime setup is:

```bash
if [ -z "$GITEA_SERVER_URL" ] || [ -z "$GITEA_ACCESS_TOKEN" ]; then
  echo "GITEA_SERVER_URL and GITEA_ACCESS_TOKEN are required" >&2
  exit 1
fi
tea login add --name sandcastle --url "$GITEA_SERVER_URL" \
  --token "$GITEA_ACCESS_TOKEN" --no-version-check 2>/dev/null || true
tea login default sandcastle
```

Run this setup before issue prompts in `onSandboxReady`. Create the label with:

```bash
tea label create --name Sandcastle --color F9A825 \
  --description "Issues for Sandcastle to work on" 2>/dev/null || true
```

Use these prompt commands, adapting shell quoting to the generated prompt:

```text
LIST_TASKS_COMMAND: tea issues list --state open --labels Sandcastle --fields index,title,body,labels,comments --output json
VIEW_TASK_COMMAND: tea issue <ID> --comments --output json
CLOSE_TASK_COMMAND: tea comment <ID> "Completed by Sandcastle" && tea issue close <ID>
```

Check the exact subcommand names against the installed `tea --help`; `tea` versions can differ.

### GitLab with `glab`

Host prerequisite and authentication:

1. Test `glab` on the host.
2. If missing, guide the user to install it from the [official GitLab CLI installation documentation](https://docs.gitlab.com/cli/), then stop until they confirm it works.
3. Ask for a GitLab personal access token with API access. For self-managed GitLab, ask for the hostname too.
4. Add these variables to `.sandcastle/.env` without printing the token:

   ```dotenv
   GITLAB_TOKEN=<REDACTED>
   # Set for self-managed GitLab; omit for gitlab.com.
   GITLAB_HOST=gitlab.example.com
   ```

5. Guide host authentication. The official CLI supports token input on stdin:

   ```bash
   printf '%s' "$GITLAB_TOKEN" | glab auth login \
     --hostname "${GITLAB_HOST:-gitlab.com}" --stdin
   glab auth status
   ```

   `GITLAB_TOKEN` takes precedence over stored credentials, so the container can authenticate without mounting the host keyring. Use the [official `glab auth login` documentation](https://docs.gitlab.com/cli/auth/login/) for versions with different flags.

Container installation pattern, based on the reference implementation in [Sandcastle PR #912](https://github.com/mattpocock/sandcastle/pull/912/changes):

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

Ensure `jq` is installed before this command. For self-managed GitLab, pass `GITLAB_HOST` through the Sandcastle environment resolver and use the selected host in `glab` commands where required.

Use these prompt commands, based on the reference implementation:

```text
LIST_TASKS_COMMAND: glab issue list --label Sandcastle --per-page 100 --output json | jq '[.[] | {number: .iid, title, body: .description, labels: (.labels // [])}]'
VIEW_TASK_COMMAND: glab issue view <ID> --comments
CLOSE_TASK_COMMAND: glab issue note <ID> --message "Completed by Sandcastle" && glab issue close <ID>
```

Create the label with:

```bash
glab label create --name "Sandcastle" \
  --description "Issues for Sandcastle to work on" \
  --color "#F9A825" 2>/dev/null || true
```

### Tracker migration completion gate

Before declaring a migration complete, search the generated setup:

```bash
grep -RInE '(^|[^a-z])(gh|github|tea|glab) ' \
  .sandcastle .sandcastle/*.md 2>/dev/null || true
```

The selected tracker must be present in the intended files, and stale GitHub commands must be absent from the tracker workflow. Validate the list command, single-issue command, comment command, close command, label command, environment variables, and container CLI.

## Phase 5 — Ignore rules and helper scripts

Preserve existing ignore rules and ensure these are present.

Root `.gitignore`:

```gitignore
node_modules/
dist/
/.sandcastle/.env
/.sandcastle/extra-certs.crt
```

`.sandcastle/.gitignore`:

```gitignore
.env
logs/
worktrees/
extra-certs.crt
```

Create executable root scripts by copying `references/workflow-template/scrun` and `scbuild` (or the project's equivalent build command). `scrun` must retain named model/thinking options, `--help`, strict unknown-option handling, and preflight validation. Do not reduce it to a silent `npx tsx` wrapper.

The GitHub template's `scrun` defaults are:

- Planner: `gpt-5.6-luna`, `high`.
- Implementer: `gpt-5.6-luna`, `medium`.
- Reviewer: `gpt-5.6-terra`, `off`.
- Merger: `gpt-5.6-terra`, `off`.

`scbuild`:

```bash
#!/usr/bin/env bash

npx @ai-hero/sandcastle podman build-image

exit $?
```

Run:

```bash
chmod u+x scrun scbuild
```

## Phase 6 — Cleanup, validation, and hand-off

Only after the run is stopped and no agent is in flight, clean Sandcastle-owned
resources. Inspect before deleting:

```bash
git worktree list
git branch --list 'sandcastle/*'
podman ps -a --filter ancestor=localhost/sandcastle:pie-subagents
podman images
```

Remove only Sandcastle worktrees and branches that no longer need review. Remove
containers created from the Sandcastle image, then remove that image and dangling
layers. Do not run broad `podman system prune` and do not remove unrelated
containers or images such as Gitea, Node, or UV bases. A stale ready token on an
open issue requires manual branch reconciliation before cleanup.

Run the cheapest checks first, then the container build:

```bash
git diff --check
npm run typecheck
npm test
./scbuild
```

If a script or package script is not present, inspect `package.json` and use the project's equivalent. Do not claim success from a command that did not run.

Verify:

- The image builds with the corporate certificate installed in Debian's trust store.
- The image contains Pi, the selected issue-tracker CLI, `git`, `curl`, and `jq` as needed.
- Pi discovers the selected models in the sandbox.
- The selected tracker credentials are passed through `.sandcastle/.env` without being logged.
- Prompt commands return the JSON shape expected by the planner.
- At most `MAX_CONCURRENT_ISSUES` issue pipelines start in one batch.
- `scrun --help` lists all eight named role options and their defaults.
- Invalid options, model IDs, and model-specific thinking levels fail before agent launch.
- Implementer/reviewer markers, approval-token ordering, and merger receipts are present in the prompts and checked by the script.
- A failed circuit breaker adds `ready-for-human`, removes `Sandcastle`, and leaves the issue open.
- The target branch contains only branches whose merger receipt and ancestry postconditions passed.
- Stale Sandcastle branches and worktrees can be removed safely after the run; unrelated branches remain.
- Secrets, certificates, logs, worktrees, and generated dependencies are ignored.

Record the final setup in `custom-pi-setup.md` or the project's equivalent durable documentation, including model roles, mounts, tracker choice, resource limit, branch workflow, and build prerequisites.

## Reference material

Read these only when the corresponding branch is active:

- [Corporate certificate build pattern](references/podman-corporate-certificates.md)
- [Issue-tracker migration details](references/issue-tracker-migration.md)
- [Pi and resource-management preferences](references/pi-and-resources.md)
- [Concrete TypeScript, prompt, mount, and coding-standard patches](references/patch-snippets.md)
- [Copyable gated workflow template](references/workflow-template/README.md)

## Revision Log

- 2026-08-24: Replaced the vendor workflow guidance with the copyable gated workflow, eight-runner batches, script-owned circuit breakers, explicit `scrun` options, and tracker-adapter instructions.
