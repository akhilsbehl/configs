# Pi and resource-management preferences

## Pi role configuration

Use these role defaults unless the user chooses alternatives after verifying availability:

| Role | Model | Thinking |
|---|---|---|
| Planner | `gpt-5.6-luna` | `high` |
| Implementer | `gpt-5.6-luna` | `medium` |
| Reviewer | `gpt-5.6-terra` | `off` |
| Merger | `gpt-5.6-terra` | `off` |

Do not pin the Pi package version. Use:

```dockerfile
RUN npm install -g @earendil-works/pi-coding-agent
```

Every new project should replicate these host Pi mounts in `piSandbox()`:

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

Verify each host path exists before adding it. Mount only required skills and extension sources, not the entire host Pi directory. Pi creates its provider lock file beside `auth.json`, so that file must be read-write. The model catalogue, skills, and extension source must remain read-only. Never expose or log auth contents.

## Optional approval wrapper

Do not add `bin/pi-approved` to ordinary Pi-agent projects. Use native `sandcastle.pi(model)` by default. Add the wrapper only when the project is itself developing a Pi extension or explicitly requires project-local Pi approval:

```bash
#!/usr/bin/env bash
set -euo pipefail
exec pi --approve "$@"
```

`--approve` trusts project-local files; it is not unrestricted tool permission bypass.

## Default fan-out

The explicit workflow template does not use unbounded fan-out. The generated parallel planner normally does:

```ts
await Promise.allSettled(issues.map(runIssuePipeline));
```

This starts every returned issue pipeline concurrently. Each pipeline runs its implementer and then reviewer sequentially. The planner runs once before fan-out and the merger runs once after fan-out in an outer iteration.

## Bounded fan-out

The explicit workflow template uses `MAX_CONCURRENT_ISSUES = 8` and processes batches:

```ts
const MAX_CONCURRENT_ISSUES = 8;
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

Ten planned issues therefore run as eight and two. A worker pool is only needed if the next issue must start as soon as an individual slot frees. Implementer and reviewer calls within one issue pipeline remain sequential; merger units remain sequential.

## Runtime capacity

Inspect both stable capacity and runtime availability:

```bash
nproc
free -h
cat /proc/loadavg
df -hT /
podman info --format 'cpus={{.Host.CPUs}} mem={{.Host.MemTotal}} rootless={{.Host.Security.Rootless}}'
podman stats --no-stream
```

Stable or slowly changing values include logical CPU count, Podman/WSL memory ceiling, swap size, and filesystem capacity. Runtime values include available memory, load, swap use, existing containers, test/build spikes, and API/network saturation.

Start conservatively. Increase one pipeline at a time. Reduce the limit if memory safety reserve is breached, swap activates, sustained load approaches CPU count, or the host becomes unresponsive.

Podman supports per-container CPU limits, such as:

```ts
podman({ cpus: 1.5 })
```

Do not assume the installed Sandcastle version exposes a container memory option.

## Revision Log

- 2026-08-24: Updated resource guidance for the explicit eight-pipeline gated workflow.
