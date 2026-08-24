// Sandcastle orchestrator — gated implement⇄review subloop with token-based
// merging. Design: ~/.richie/ephemeral/sandcastle-workflow-sketch.md (v3 final).
//
// Per outer iteration:
//   1. Plan     — LLM picks unblocked open issues, emits <plan> JSON.
//   2. Subloop  — per issue (parallel, batched): implement⇄review up to 4
//                 rounds; reviewer is a gate that never fixes and must run
//                 tests independently; approval posts READY-FOR-MERGER-AGENT
//                 as the last GitHub comment on the ticket.
//   3. Merge    — script pre-filters branches by that token (authoritative),
//                 then one merger agent processes branches sequentially:
//                 merge → ≤3-turn conflict resolution → general test run →
//                 close on success; single failure comment w/ guidance +
//                 SUPERSEDED-READY-TOKEN on failure.
//   4. Ledger   — script tracks failed rounds per issue in state.json and
//                 applies ready-for-human at the 3rd failure.
//
// The script never invokes project tooling (tests are agent-run) and never
// trusts an LLM with bookkeeping.

import * as fs from "node:fs";
import { execFileSync } from "node:child_process";
import * as sandcastle from "@ai-hero/sandcastle";
import { podman } from "@ai-hero/sandcastle/sandboxes/podman";
import { z } from "zod";

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const MAX_ITERATIONS = 32;
const MAX_CONCURRENT_ISSUES = 8;

// Subloop budgets: 64/16 x 4.
const IMPLEMENT_ROUNDS = 4;
const IMPLEMENTER_ITERATIONS = 64;
const REVIEWER_ITERATIONS = 16;

const MERGER_ITERATIONS = 40;
const FAILURE_ESCALATION_THRESHOLD = 3;

const STATE_FILE = "./.sandcastle/state.json";

const hooks = {
  sandbox: { onSandboxReady: [{ command: "npm install" }] },
};

const piSandbox = () =>
  podman({
    mounts: [
      {
        hostPath: "~/.pi/agent/auth.json",
        sandboxPath: "/home/agent/.pi/agent/auth.json",
        // Pi refreshes provider availability and creates a sibling lock file.
        readonly: false,
      },
      {
        hostPath: "~/.pi/agent/models-store.json",
        sandboxPath: "/home/agent/.pi/agent/models-store.json",
        readonly: true,
      },
      ...[
        "code-review",
        "codebase-design",
        "diagnosing-bugs",
        "implement",
        "improve-codebase-architecture",
        "resolving-merge-conflicts",
        "tdd",
        "triage",
      ].map((skill) => ({
        hostPath: `~/.agents/skills/${skill}`,
        sandboxPath: `/home/agent/.pi/agent/skills/${skill}`,
        readonly: true,
      })),
      {
        hostPath:
          "~/.pi/agent/git/github.com/algal/pi-openai-server-compaction",
        sandboxPath:
          "/home/agent/.pi/agent/git/github.com/algal/pi-openai-server-compaction",
        readonly: true,
      },
    ],
  });

type ThinkingLevel = "off" | "minimal" | "low" | "medium" | "high" | "xhigh";
type Role = "planner" | "implementer" | "reviewer" | "merger";

type ModelRecord = {
  id: string;
  reasoning?: boolean;
  thinkingLevelMap?: Record<string, string | null>;
};

type RoleOptions = Record<Role, { model: string; thinking: ThinkingLevel }>;

const DEFAULTS: RoleOptions = {
  planner: { model: "gpt-5.6-luna", thinking: "high" },
  implementer: { model: "gpt-5.6-luna", thinking: "medium" },
  reviewer: { model: "gpt-5.6-terra", thinking: "off" },
  merger: { model: "gpt-5.6-terra", thinking: "off" },
};

function printUsage(): void {
  console.log(`Usage: ./scrun [options]

Options:
  --planner-model MODEL          Default: ${DEFAULTS.planner.model}
  --planner-thinking LEVEL       Default: ${DEFAULTS.planner.thinking}
  --implementer-model MODEL      Default: ${DEFAULTS.implementer.model}
  --implementer-thinking LEVEL   Default: ${DEFAULTS.implementer.thinking}
  --reviewer-model MODEL         Default: ${DEFAULTS.reviewer.model}
  --reviewer-thinking LEVEL      Default: ${DEFAULTS.reviewer.thinking}
  --merger-model MODEL           Default: ${DEFAULTS.merger.model}
  --merger-thinking LEVEL        Default: ${DEFAULTS.merger.thinking}
  --target-branch BRANCH         Branch issue branches merge into. Default: the
                                 branch sandcastle is launched from.
  -h, --help                     Show this help

Thinking levels: off, minimal, low, medium, high, xhigh`);
}

function parseOptions(): RoleOptions {
  const options = structuredClone(DEFAULTS) as RoleOptions;
  const args = process.argv.slice(2);
  const optionMap: Record<string, { role: Role; field: "model" | "thinking" }> = {
    "--planner-model": { role: "planner", field: "model" },
    "--planner-thinking": { role: "planner", field: "thinking" },
    "--implementer-model": { role: "implementer", field: "model" },
    "--implementer-thinking": { role: "implementer", field: "thinking" },
    "--reviewer-model": { role: "reviewer", field: "model" },
    "--reviewer-thinking": { role: "reviewer", field: "thinking" },
    "--merger-model": { role: "merger", field: "model" },
    "--merger-thinking": { role: "merger", field: "thinking" },
  };

  for (let index = 0; index < args.length; index++) {
    const argument = args[index]!;
    if (argument === "-h" || argument === "--help") {
      printUsage();
      process.exit(0);
    }
    if (argument === "--target-branch") {
      if (index + 1 >= args.length) throw new Error(`Incomplete option: ${argument}. Use --help for usage.`);
      index += 1; // consumed by targetBranch(); not a role option
      continue;
    }
    const option = optionMap[argument];
    if (!option || index + 1 >= args.length) {
      throw new Error(`Unknown or incomplete option: ${argument}. Use --help for usage.`);
    }
    const value = args[++index]!;
    if (option.field === "thinking" && !["off", "minimal", "low", "medium", "high", "xhigh"].includes(value)) {
      throw new Error(`Invalid ${argument} value ${JSON.stringify(value)}. Use --help for valid levels.`);
    }
    options[option.role][option.field] = value as never;
  }
  return options;
}

function loadModels(): ModelRecord[] {
  const path = `${process.env.HOME ?? ""}/.pi/agent/models-store.json`;
  try {
    const registry = JSON.parse(fs.readFileSync(path, "utf8")) as Record<string, { models?: ModelRecord[] }>;
    return Object.values(registry).flatMap((provider) => provider.models ?? []);
  } catch (error) {
    throw new Error(`Could not read ${path}: ${error}`);
  }
}

function validateOptions(options: RoleOptions): void {
  const models = loadModels();
  for (const role of Object.keys(options) as Role[]) {
    const selection = options[role];
    const model = models.find((candidate) => candidate.id === selection.model);
    if (!model) {
      throw new Error(`${role}: model ${JSON.stringify(selection.model)} is not available in ~/.pi/agent/models-store.json`);
    }
    const map = model.thinkingLevelMap;
    const explicitlyUnsupported = map?.[selection.thinking] === null;
    const extendedLevelMissing = selection.thinking === "xhigh" && map?.[selection.thinking] === undefined;
    if (explicitlyUnsupported || extendedLevelMissing || (model.reasoning === false && selection.thinking !== "off")) {
      throw new Error(`${role}: thinking level ${selection.thinking} is not valid for model ${selection.model}`);
    }
  }
}

const roleOptions = parseOptions();
validateOptions(roleOptions);
const piPlanner = () => sandcastle.pi(roleOptions.planner.model, { thinking: roleOptions.planner.thinking });
const piImplementer = () =>
  sandcastle.pi(roleOptions.implementer.model, { thinking: roleOptions.implementer.thinking });
const piReviewer = () => sandcastle.pi(roleOptions.reviewer.model, { thinking: roleOptions.reviewer.thinking });
const piMerger = () => sandcastle.pi(roleOptions.merger.model, { thinking: roleOptions.merger.thinking });

const copyToWorktree = ["node_modules"];

// ---------------------------------------------------------------------------
// Structured output contracts
// ---------------------------------------------------------------------------

const planSchema = z.object({
  issues: z.array(
    z.object({ id: z.string(), title: z.string(), branch: z.string() }),
  ),
});

type Candidate = {
  id: string;
  title: string;
  body: string;
  labels: string[];
  comments: string[];
  branch: string;
};

// Reviewer verdicts are NOT extracted via sandbox.run({ output }) — the
// vendored Sandbox.run does not support structured output (only the
// standalone sandcastle.run does). Instead the reviewer posts VERDICT lines
// and the READY-FOR-MERGER-AGENT token as GitHub comments, which the script
// reads back. The ticket stays the single source of truth.

// ---------------------------------------------------------------------------
// Failure ledger (script-owned bookkeeping)
// ---------------------------------------------------------------------------

type Ledger = { failures: Record<string, number> };

function loadLedger(): Ledger {
  try {
    return JSON.parse(fs.readFileSync(STATE_FILE, "utf8")) as Ledger;
  } catch {
    return { failures: {} };
  }
}

function saveLedger(ledger: Ledger): void {
  fs.writeFileSync(STATE_FILE, JSON.stringify(ledger, null, 2));
}

// ---------------------------------------------------------------------------
// GitHub helpers (mechanical reads/writes only — no judgement)
// ---------------------------------------------------------------------------

function sh(cmd: string): string {
  // Runs on the HOST only, for mechanical gh/git reads and writes.
  return execFileSync("bash", ["-c", cmd], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  }).trim();
}

function ghJson<T>(args: string[]): T | undefined {
  try {
    return JSON.parse(
      execFileSync("gh", args, { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }),
    ) as T;
  } catch (err) {
    console.error(`  ! gh read failed: ${args.join(" ")}: ${err}`);
    return undefined;
  }
}

function issueComments(issueId: string): string[] | undefined {
  const result = ghJson<{ comments: { body: string }[] }>([
    "issue",
    "view",
    issueId,
    "--json",
    "comments",
  ]);
  return result?.comments.map((comment) => comment.body);
}

/** true/false when readable; undefined means the control-plane read failed. */
function hasValidReadyToken(issueId: string): boolean | undefined {
  const comments = issueComments(issueId);
  if (!comments) return undefined;
  return comments.at(-1) === "READY-FOR-MERGER-AGENT";
}

function hasCommentMarker(issueId: string, marker: string): boolean | undefined {
  const comments = issueComments(issueId);
  if (!comments) return undefined;
  return comments.some((body) => body.includes(marker));
}

function issueState(issueId: string): string | undefined {
  const result = ghJson<{ state: string }>(["issue", "view", issueId, "--json", "state"]);
  return result?.state;
}

function issueIsOpen(issueId: string): boolean | undefined {
  const state = issueState(issueId);
  return state === undefined ? undefined : state === "OPEN";
}

function addLabel(issueId: string, label: string): void {
  try {
    sh(`gh issue edit ${issueId} --add-label "${label}"`);
  } catch (err) {
    console.error(`  ! could not label #${issueId}: ${err}`);
  }
}

function removeLabel(issueId: string, label: string): void {
  try {
    sh(`gh issue edit ${issueId} --remove-label "${label}"`);
  } catch (err) {
    console.error(`  ! could not remove label from #${issueId}: ${err}`);
  }
}

function markReadyForHuman(issueId: string): void {
  addLabel(issueId, "ready-for-human");
  removeLabel(issueId, "Sandcastle");
}

function commentIssue(issueId: string, body: string): void {
  try {
    execFileSync("gh", ["issue", "comment", issueId, "--body", body], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    });
  } catch (err) {
    console.error(`  ! could not comment on #${issueId}: ${err}`);
  }
}

function closeIssue(issueId: string, message: string): void {
  try {
    execFileSync("gh", ["issue", "close", issueId, "--comment", message], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    });
  } catch (err) {
    console.error(`  ! could not close #${issueId}: ${err}`);
  }
}

function reopenIssue(issueId: string): void {
  try {
    execFileSync("gh", ["issue", "reopen", issueId], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    });
  } catch (err) {
    console.error(`  ! could not reopen #${issueId}: ${err}`);
  }
}

function supersedeToken(issueId: string, reason: string): void {
  commentIssue(
    issueId,
    `SUPERSEDED-READY-TOKEN\n\n${reason}\nThe ticket remains open for a later retry.`,
  );
}

function worktreeIsClean(worktreePath: string): boolean | undefined {
  try {
    return sh(`git -C "${worktreePath}" status --porcelain --untracked-files=all`) === "";
  } catch (err) {
    console.error(`  ! could not inspect worktree ${worktreePath}: ${err}`);
    return undefined;
  }
}

function branchIsIntegrated(branch: string, targetBranch: string): boolean {
  try {
    execFileSync("git", ["merge-base", "--is-ancestor", branch, targetBranch], {
      stdio: "ignore",
    });
    return true;
  } catch {
    return false;
  }
}

const mdList = (items: string[]) => items.map((i) => `- ${i}`).join("\n");

// ---------------------------------------------------------------------------
// Main loop
// ---------------------------------------------------------------------------

const ledger = loadLedger();

/** Default branch of this repo, resolved once — never hardcoded.
 *  Note: sandcastle injects TARGET_BRANCH into prompts itself; this is for
 *  any host-side logic that needs it. */
function defaultBranch(): string {
  try {
    return (
      sh(
        "git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|^origin/||'",
      ) || "master"
    );
  } catch {
    return "master";
  }
}
/** Integration target branch: explicit --target-branch flag wins, else the
 *  branch sandcastle was launched from, else the remote default. Resolved once.
 *  Note: sandcastle injects TARGET_BRANCH into prompts itself; this is for
 *  any host-side logic that needs it. */
function targetBranch(): string {
  if (targetBranchCache) return targetBranchCache;
  const flagIndex = process.argv.indexOf("--target-branch");
  const override = flagIndex >= 0 ? process.argv[flagIndex + 1] : undefined;
  if (override) {
    targetBranchCache = override;
    return targetBranchCache;
  }
  targetBranchCache = sh("git rev-parse --abbrev-ref HEAD") || defaultBranch();
  return targetBranchCache;
}
let targetBranchCache: string | undefined;

for (let iteration = 1; iteration <= MAX_ITERATIONS; iteration++) {
  const runId = `sandcastle-${Date.now()}-${iteration}`;
  console.log(`\n=== Iteration ${iteration}/${MAX_ITERATIONS} ===\n`);

  // ---- Phase 1: Plan ------------------------------------------------------
  // The script does ALL mechanical filtering; the planner only reasons over
  // what is handed to it.
  let candidates: Candidate[];
  try {
    const raw = sh(
      `gh issue list --state open --label Sandcastle --limit 100 --json number,title,body,labels,comments`,
    );
    candidates = (
      JSON.parse(raw) as {
        number: number;
        title: string;
        body: string;
        labels: { name: string }[];
        comments: { body: string }[];
      }[]
    )
      .map((issue) => ({
        id: String(issue.number),
        title: issue.title,
        body: issue.body,
        labels: issue.labels.map((label) => label.name),
        comments: issue.comments.map((comment) => comment.body),
        branch: `sandcastle/issue-${issue.number}`,
      }))
      .filter((issue) => {
        const ready = hasValidReadyToken(issue.id);
        if (ready === undefined) {
          console.error(`  ! skipping #${issue.id}: could not read issue comments`);
          return false;
        }
        return !ready;
      });
  } catch (err) {
    console.error(`Planner input acquisition failed; skipping iteration: ${err}`);
    continue;
  }

  if (candidates.length === 0) {
    console.log("No unblocked issues to work on. Exiting.");
    break;
  }

  let plannedIssues: z.infer<typeof planSchema>["issues"];
  try {
    const plan = await sandcastle.run({
      hooks,
      sandbox: piSandbox(),
      name: "planner",
      maxIterations: 1,
      agent: piPlanner(),
      promptFile: "./.sandcastle/plan-prompt.md",
      promptArgs: {
        ISSUES_JSON: JSON.stringify(candidates),
      },
      output: sandcastle.Output.object({
        tag: "plan",
        schema: planSchema,
        maxRetries: 3,
      }),
    });
    plannedIssues = plan.output.issues;
  } catch (err) {
    console.error(`Planner handoff failed; skipping iteration: ${err}`);
    continue;
  }

  // Authority gate: only accept exact candidates and deterministic branches.
  const candidateById = new Map(candidates.map((candidate) => [candidate.id, candidate]));
  const issues: Candidate[] = [];
  for (const planned of plannedIssues) {
    const candidate = candidateById.get(planned.id);
    if (!candidate || candidate.title !== planned.title || candidate.branch !== planned.branch) {
      console.error(`  ! rejecting unauthorised planner entry: ${JSON.stringify(planned)}`);
      continue;
    }
    const ready = hasValidReadyToken(candidate.id);
    if (ready !== false) continue;
    issues.push(candidate);
  }

  if (issues.length === 0) {
    console.log("No unblocked issues to work on. Exiting.");
    break;
  }

  console.log(`Planning complete. ${issues.length} issue(s) to work:`);
  for (const issue of issues) {
    console.log(`  ${issue.id}: ${issue.title} → ${issue.branch}`);
  }

  // ---- Phase 2: Implement ⇄ Review subloop (parallel pipelines) ------------
  const approved: { id: string; title: string; branch: string }[] = [];

  for (
    let offset = 0;
    offset < issues.length;
    offset += MAX_CONCURRENT_ISSUES
  ) {
    const batch = issues.slice(offset, offset + MAX_CONCURRENT_ISSUES);
    const results = await Promise.allSettled(
      batch.map(async (issue) => {
        const sandbox = await sandcastle.createSandbox({
          branch: issue.branch,
          sandbox: piSandbox(),
          hooks,
          copyToWorktree,
        });

        try {
          const clean = worktreeIsClean(sandbox.worktreePath);
          if (clean !== true) {
            const message =
              clean === false
                ? "Sandcastle found uncommitted worktree changes before the agent started; refusing to mix state."
                : "Sandcastle could not inspect the worktree before the agent started.";
            commentIssue(issue.id, `${message} Inspect the preserved worktree before retrying.`);
            markReadyForHuman(issue.id);
            return false;
          }

          let approvedFlag = false;

          for (let round = 1; round <= IMPLEMENT_ROUNDS; round++) {
            const implementationMarker = `SANDCASTLE-IMPLEMENTATION-ROUND: ${runId}:${round}`;
            const implementation = await sandbox.run({
              name: `implementer-r${round}`,
              maxIterations: IMPLEMENTER_ITERATIONS,
              completionSignal: "<promise>COMPLETE</promise>",
              agent: piImplementer(),
              promptFile: "./.sandcastle/implement-prompt.md",
              promptArgs: {
                TASK_ID: issue.id,
                ISSUE_TITLE: issue.title,
                BRANCH: issue.branch,
                RUN_ID: runId,
                ROUND: String(round),
                ROUND_COUNT: String(IMPLEMENT_ROUNDS),
              },
            });

            if (!implementation.completionSignal || hasCommentMarker(issue.id, implementationMarker) !== true) {
              const message =
                `Sandcastle implementer did not complete the durable handoff for round ${round}; no review was started. ` +
                "The ticket remains open for a later retry.";
              console.error(`  ! #${issue.id}: ${message}`);
              commentIssue(issue.id, message);
              if (round === IMPLEMENT_ROUNDS) markReadyForHuman(issue.id);
              return false;
            }

            const reviewMarkerPrefix = `SANDCASTLE-REVIEW-ROUND: ${runId}:${round}`;
            const review = await sandbox.run({
              name: `reviewer-r${round}`,
              maxIterations: REVIEWER_ITERATIONS,
              completionSignal: "<promise>COMPLETE</promise>",
              agent: piReviewer(),
              promptFile: "./.sandcastle/review-prompt.md",
              promptArgs: {
                TASK_ID: issue.id,
                BRANCH: issue.branch,
                RUN_ID: runId,
                ROUND: String(round),
                ROUND_COUNT: String(IMPLEMENT_ROUNDS),
              },
            });

            const ready = hasValidReadyToken(issue.id);
            const approvedMarker = hasCommentMarker(
              issue.id,
              `${reviewMarkerPrefix}: APPROVED`,
            );
            const rejectedMarker = hasCommentMarker(
              issue.id,
              `${reviewMarkerPrefix}: REJECTED`,
            );

            if (
              review.completionSignal &&
              ready === true &&
              approvedMarker === true
            ) {
              approvedFlag = true;
              break;
            }
            if (!review.completionSignal || (!rejectedMarker && !approvedMarker)) {
              const message =
                `Sandcastle reviewer did not complete the durable handoff for round ${round}; no valid review marker was accepted. ` +
                "The ticket remains open for a later retry.";
              console.error(`  ! #${issue.id}: ${message}`);
              commentIssue(issue.id, message);
              break;
            }
            if (rejectedMarker && ready !== true) {
              console.log(`  · #${issue.id} round ${round}: gate token not posted`);
            }
          }

          if (approvedFlag) {
            approved.push(issue);
          } else {
            const message =
              `Sandcastle exhausted the ${IMPLEMENT_ROUNDS}-round implement/review budget without approval. ` +
              "The ticket has been marked ready-for-human and will not be selected by later outer iterations.";
            console.error(`  ! #${issue.id}: ${message}`);
            commentIssue(issue.id, message);
            markReadyForHuman(issue.id);
          }
          return true;
        } finally {
          await sandbox.close();
        }
      }),
    );

    results.forEach((r, i) => {
      if (r.status === "rejected") {
        console.error(`  ✗ #${batch[i]!.id} pipeline failed: ${r.reason}`);
      }
    });
  }

  if (approved.length === 0) {
    console.log("\nNo branches approved for merge this iteration.");
    continue;
  }

  console.log(
    `\nApproved for merge:\n${mdList(approved.map((a) => `${a.id}: ${a.title}`))}`,
  );

  // ---- Phase 3: Merger agent (token-gated, sequential units of work) -------
  let mergerCompleted = false;
  try {
    const merger = await sandcastle.run({
      hooks,
      sandbox: piSandbox(),
      name: "merger",
      maxIterations: MERGER_ITERATIONS,
      completionSignal: "<promise>COMPLETE</promise>",
      agent: piMerger(),
      promptFile: "./.sandcastle/merge-prompt.md",
      promptArgs: {
        BRANCHES: mdList(approved.map((a) => a.branch)),
        ISSUES: mdList(approved.map((a) => `${a.id}: ${a.title}`)),
      },
    });
    mergerCompleted = Boolean(merger.completionSignal);
  } catch (err) {
    console.error(`Merger handoff failed: ${err}`);
  }

  // ---- Phase 4: Mechanical postconditions & escalation --------------------
  for (const issue of approved) {
    const integrated = mergerCompleted && branchIsIntegrated(issue.branch, targetBranch());
    const state = issueState(issue.id);

    if (integrated && state === "OPEN") {
      // The script owns the final closure after branch integration is proven.
      closeIssue(issue.id, "Completed by Sandcastle after verified branch integration");
    } else if (!integrated) {
      if (state === "CLOSED") reopenIssue(issue.id);
      supersedeToken(
        issue.id,
        mergerCompleted
          ? `Branch ${issue.branch} was not integrated into ${targetBranch()}.`
          : "The merger did not complete; integration and closure were not accepted.",
      );
    }

    const finalState = issueState(issue.id);
    const finalIntegrated = branchIsIntegrated(issue.branch, targetBranch());
    if (finalState === "CLOSED" && finalIntegrated && mergerCompleted) {
      delete ledger.failures[issue.id];
      continue;
    }

    ledger.failures[issue.id] = (ledger.failures[issue.id] ?? 0) + 1;
    const n = ledger.failures[issue.id];
    console.error(`  ! #${issue.id} failed merger postconditions (${n})`);
    if (n >= FAILURE_ESCALATION_THRESHOLD) {
      markReadyForHuman(issue.id);
      console.error(
        `  ! #${issue.id} hit ${FAILURE_ESCALATION_THRESHOLD} failures — labelled ready-for-human`,
      );
    }
  }
  saveLedger(ledger);
}

console.log("\nAll done.");
