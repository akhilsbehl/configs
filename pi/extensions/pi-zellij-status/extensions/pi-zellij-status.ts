import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { execFile } from "node:child_process";
import { fileURLToPath } from "node:url";
import { join } from "node:path";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const IDLE_STATUS = "idle";
const WAITING_STATUS = "waiting";
const CHANNEL_PERMISSION_PROMPT = "permissions:ui_prompt";
const CHANNEL_PERMISSION_DECISION = "permissions:decision";
const CHANNEL_ASK_USER_BLOCKED = "rpiv:ask-user:blocked";
const PLAN_QUESTION_TOOL = "plan_mode_question";
const PLAN_STATE_ENTRY = "plan-mode-state";

type Status = "idle" | "running" | "waiting" | undefined;
type StatusLabel = Exclude<Status, undefined> | `I${number}/R${number}/W${number}`;
type Pane = { id: number; title?: string; tab_id?: number; tab_name?: string };
type Tab = { tab_id: number; name?: string };
type PlanStateEntry = { type?: string; customType?: string; data?: unknown };

export default function piZellijStatus(pi: ExtensionAPI): void {
  pi.on("resources_discover", () => ({
    skillPaths: [join(fileURLToPath(new URL("..", import.meta.url)), "skills")],
  }));

  const session = process.env.ZELLIJ_SESSION_NAME;
  const paneId = process.env.ZELLIJ_PANE_ID;
  if (!session || !paneId) return;
  const numericPaneId = paneId.startsWith("terminal_") ? paneId.slice("terminal_".length) : paneId;

  let waitingReasons = new Map<string, number>();
  let idle = false;
  let updateQueue = Promise.resolve();
  let disposed = false;

  const enqueueUpdate = () => {
    updateQueue = updateQueue.then(() => updateZellij()).catch(() => undefined);
  };

  const waitingCount = () => [...waitingReasons.values()].reduce((sum, value) => sum + value, 0);

  const changeWaiting = (reason: string, delta: 1 | -1) => {
    const wasWaiting = waitingCount() > 0;
    const next = Math.max(0, (waitingReasons.get(reason) ?? 0) + delta);
    if (next === 0) waitingReasons.delete(reason);
    else waitingReasons.set(reason, next);
    if (!wasWaiting && waitingCount() > 0) process.stdout.write("\x07");
    idle = false;
    enqueueUpdate();
  };

  const ensureWaiting = (reason: string) => {
    if ((waitingReasons.get(reason) ?? 0) === 0) changeWaiting(reason, 1);
  };

  const clearWaiting = (reason: string) => {
    if ((waitingReasons.get(reason) ?? 0) === 0) return;
    waitingReasons.delete(reason);
    idle = false;
    enqueueUpdate();
  };

  const setIdle = () => {
    if (waitingCount() > 0) return;
    if (!idle) process.stdout.write("\x07");
    idle = true;
    enqueueUpdate();
  };

  const clearIdle = () => {
    if (!idle) return;
    idle = false;
    enqueueUpdate();
  };

  pi.on("input", () => {
    clearIdle();
    // A new chat turn is also an explicit action on a completed-plan menu.
    clearWaiting("plan-review");
  });

  pi.on("agent_settled", (_event, ctx) => {
    setIdle();
    // pi-plan-mode presents its completed-plan menu from its own
    // agent_settled handler and currently exposes no public event for it.
    setImmediate(() => {
      if (disposed) return;
      if (planReviewIsReady(ctx)) ensureWaiting("plan-review");
      else clearWaiting("plan-review");
    });
  });

  pi.on("tool_execution_start", (event) => {
    if (event.toolName === PLAN_QUESTION_TOOL) ensureWaiting("plan-question");
  });

  pi.on("tool_execution_end", (event) => {
    if (event.toolName === PLAN_QUESTION_TOOL) changeWaiting("plan-question", -1);
  });

  const unsubscribePermissionPrompt = pi.events.on(CHANNEL_PERMISSION_PROMPT, () => {
    ensureWaiting("permission");
  });
  const unsubscribePermissionDecision = pi.events.on(CHANNEL_PERMISSION_DECISION, () => {
    changeWaiting("permission", -1);
  });
  const unsubscribeAskUser = pi.events.on(CHANNEL_ASK_USER_BLOCKED, (data) => {
    if (isRecord(data) && data.active === true) ensureWaiting("ask-user");
    else if (isRecord(data) && data.active === false) changeWaiting("ask-user", -1);
  });

  pi.on("session_shutdown", async () => {
    disposed = true;
    unsubscribePermissionPrompt();
    unsubscribePermissionDecision();
    unsubscribeAskUser();
    await updateQueue.catch(() => undefined);
    await clearZellijStatus().catch(() => undefined);
  });

  // A newly started Pi session contributes as idle immediately.
  idle = true;
  enqueueUpdate();

  function currentStatus(): Status {
    if (waitingCount() > 0) return "waiting";
    if (idle) return "idle";
    return "running";
  }

  async function updateZellij(): Promise<void> {
    const panes = await listPanes();
    const ownPane = panes.find((pane) => String(pane.id) === numericPaneId);
    if (!ownPane || ownPane.tab_id === undefined) return;

    const status = currentStatus();
    await action("rename-pane", "--pane-id", paneId, appendStatus(stripStatus(ownPane.title ?? "pi"), status));

    const refreshedPanes = await listPanes();
    const tabPanes = refreshedPanes.filter((pane) => pane.tab_id === ownPane.tab_id);
    const tab = await currentTab(ownPane.tab_id);
    const baseTabName = stripStatus(tab?.name ?? ownPane.tab_name ?? "tab");
    const tabStatus = aggregateTabStatus(tabPanes, numericPaneId, status);
    await action("rename-tab", "--tab-id", String(ownPane.tab_id), appendStatus(baseTabName, tabStatus));
  }

  async function clearZellijStatus(): Promise<void> {
    const panes = await listPanes();
    const ownPane = panes.find((pane) => String(pane.id) === numericPaneId);
    if (!ownPane || ownPane.tab_id === undefined) return;

    await action("rename-pane", "--pane-id", paneId, stripStatus(ownPane.title ?? "pi"));

    const refreshedPanes = await listPanes();
    const tabPanes = refreshedPanes.filter((pane) => pane.tab_id === ownPane.tab_id && String(pane.id) !== numericPaneId);
    const tab = await currentTab(ownPane.tab_id);
    const baseTabName = stripStatus(tab?.name ?? ownPane.tab_name ?? "tab");
    const tabStatus = aggregateTabStatus(tabPanes, numericPaneId, undefined);
    await action("rename-tab", "--tab-id", String(ownPane.tab_id), appendStatus(baseTabName, tabStatus));
  }

  async function listPanes(): Promise<Pane[]> {
    const output = await zellij("action", "list-panes", "--json");
    const parsed: unknown = JSON.parse(output);
    if (!Array.isArray(parsed)) throw new Error("Unexpected zellij list-panes response");
    return parsed as Pane[];
  }

  async function currentTab(tabId: number): Promise<Tab | undefined> {
    const output = await zellij("action", "list-tabs", "--json");
    const parsed: unknown = JSON.parse(output);
    if (!Array.isArray(parsed)) throw new Error("Unexpected zellij list-tabs response");
    return (parsed as Tab[]).find((tab) => tab.tab_id === tabId);
  }

  async function action(...args: string[]): Promise<void> {
    await zellij("action", ...args);
  }

  async function zellij(...args: string[]): Promise<string> {
    const result = await execFileAsync("zellij", ["--session", session, ...args], { maxBuffer: 1024 * 1024 });
    return result.stdout;
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function stripStatus(name: string): string {
  // Remove suffixes we have appended. Repeat to repair names produced by the
  // previous implementation, which could leave nested suffixes behind.
  let base = name;
  let suffix = getStatusSuffix(base);
  while (suffix !== undefined) {
    base = base.slice(0, base.lastIndexOf(" ["));
    suffix = getStatusSuffix(base);
  }
  return base;
}

function appendStatus(name: string, status: StatusLabel | undefined): string {
  return status ? `${name} [${status}]` : name;
}

function getStatusSuffix(name: string): string | undefined {
  const start = name.lastIndexOf(" [");
  if (start < 0 || !name.endsWith("]")) return undefined;
  const suffix = name.slice(start + 2, -1);
  return isStatusSuffix(suffix) ? suffix : undefined;
}

function isStatusSuffix(suffix: string): boolean {
  if (!suffix) return false;
  if (isTabTally(suffix)) return true;
  return suffix.split(", ").every((token) => {
    const colon = token.indexOf(":");
    const status = colon < 0 ? token : token.slice(0, colon);
    const detail = colon < 0 ? "" : token.slice(colon + 1);
    return (status === IDLE_STATUS || status === "running" || status === WAITING_STATUS)
      && (colon < 0 || detail.length > 0)
      && !detail.includes("[")
      && !detail.includes("]");
  });
}

function isTabTally(suffix: string): suffix is `I${number}/R${number}/W${number}` {
  const parts = suffix.split("/");
  if (parts.length !== 3) return false;
  return ["I", "R", "W"].every((prefix, index) => {
    const part = parts[index];
    if (!part || !part.startsWith(prefix)) return false;
    const count = part.slice(prefix.length);
    return count.length > 0 && Number.isInteger(Number(count)) && Number(count) >= 0;
  });
}

function statusFromTitle(title: string | undefined): Status {
  const suffix = title === undefined ? undefined : getStatusSuffix(title);
  if (suffix === undefined) return undefined;
  const statuses = suffix.split(", ").map(statusFromToken);
  if (statuses.includes(WAITING_STATUS)) return WAITING_STATUS;
  if (statuses.includes(IDLE_STATUS)) return IDLE_STATUS;
  return undefined;
}

function statusFromToken(token: string): Status {
  const colon = token.indexOf(":");
  const status = colon < 0 ? token : token.slice(0, colon);
  if (status === WAITING_STATUS) return WAITING_STATUS;
  if (status === IDLE_STATUS) return IDLE_STATUS;
  if (status === "running") return "running";
  return undefined;
}

function aggregateTabStatus(panes: Pane[], ownPaneId: string, ownStatus: Status): StatusLabel | undefined {
  const counts = { idle: 0, running: 0, waiting: 0 };
  for (const pane of panes) {
    const status = String(pane.id) === ownPaneId
      ? ownStatus
      : statusFromTitle(pane.title);
    if (status === undefined) continue;
    counts[status]++;
  }
  const contributingPanes = counts.idle + counts.running + counts.waiting;
  if (contributingPanes === 0) return undefined;
  return `I${counts.idle}/R${counts.running}/W${counts.waiting}`;
}

function planReviewIsReady(ctx: ExtensionContext): boolean {
  const entries = ctx.sessionManager.getBranch() as unknown as PlanStateEntry[];
  const latest = [...entries].reverse().find((entry) => entry.type === "custom" && entry.customType === PLAN_STATE_ENTRY);
  if (!latest || !isRecord(latest.data)) return false;
  return latest.data.awaitingAction === true && typeof latest.data.latestPlan === "string";
}
