import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { execFile } from "node:child_process";
import { fileURLToPath } from "node:url";
import { join } from "node:path";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const STATUS_RE = /\s+\[(?:idle|waiting)(?::[^\]]+)?\]$/;
const CHANNEL_PERMISSION_PROMPT = "permissions:ui_prompt";
const CHANNEL_PERMISSION_DECISION = "permissions:decision";
const CHANNEL_ASK_USER_BLOCKED = "rpiv:ask-user:blocked";
const PLAN_QUESTION_TOOL = "plan_mode_question";
const PLAN_STATE_ENTRY = "plan-mode-state";

type Status = "idle" | "waiting" | undefined;
type Pane = {
  id: number;
  title?: string;
  tab_id?: number;
  tab_name?: string;
};
type Tab = { tab_id: number; name?: string };
type PlanStateEntry = { type?: string; customType?: string; data?: unknown };

export default function piZellijStatus(pi: ExtensionAPI): void {
  pi.on("resources_discover", () => ({
    skillPaths: [join(fileURLToPath(new URL("..", import.meta.url)), "skills")],
  }));

  const session = process.env.ZELLIJ_SESSION_NAME;
  const paneId = process.env.ZELLIJ_PANE_ID;
  if (!session || !paneId) return;

  let waitingReasons = new Map<string, number>();
  let idle = false;
  let updateQueue = Promise.resolve();
  let disposed = false;

  const enqueueUpdate = () => {
    updateQueue = updateQueue
      .then(() => updateZellij())
      .catch(() => undefined);
  };

  const changeWaiting = (reason: string, delta: 1 | -1) => {
    const wasWaiting = waitingCount() > 0;
    const next = Math.max(0, (waitingReasons.get(reason) ?? 0) + delta);
    if (next === 0) waitingReasons.delete(reason);
    else waitingReasons.set(reason, next);
    if (!wasWaiting && waitingCount() > 0) process.stdout.write("\x07");
    idle = false;
    notifyIfNeeded();
  };

  const setIdle = () => {
    if (waitingCount() > 0) return;
    idle = true;
    enqueueUpdate();
  };

  const clearIdle = () => {
    if (!idle) return;
    idle = false;
    enqueueUpdate();
  };

  const notifyIfNeeded = () => {
    enqueueUpdate();
  };

  pi.on("input", () => {
    // A new user turn means the user has returned to this Pi instance.
    clearIdle();
  });

  pi.on("agent_settled", (_event, ctx) => {
    setIdle();

    // pi-plan-mode presents its completed-plan menu from its own
    // agent_settled handler and currently exposes no public event for it.
    // Defer this check until sibling handlers have persisted their state.
    setImmediate(() => {
      if (disposed || !planReviewIsReady(ctx)) return;
      changeWaiting("plan-review", 1);
    });
  });

  pi.on("tool_execution_start", (event) => {
    if (event.toolName === PLAN_QUESTION_TOOL) {
      changeWaiting("plan-question", 1);
    }
  });

  pi.on("tool_execution_end", (event) => {
    if (event.toolName === PLAN_QUESTION_TOOL) {
      changeWaiting("plan-question", -1);
    }
  });

  // @gotgenes/pi-permission-system public event channels.
  const unsubscribePermissionPrompt = pi.events.on(CHANNEL_PERMISSION_PROMPT, () => {
    changeWaiting("permission", 1);
  });
  const unsubscribePermissionDecision = pi.events.on(CHANNEL_PERMISSION_DECISION, () => {
    changeWaiting("permission", -1);
  });

  // @juicesharp/rpiv-ask-user-question public event channel.
  const unsubscribeAskUser = pi.events.on(CHANNEL_ASK_USER_BLOCKED, (data) => {
    const active = isRecord(data) && data.active === true;
    const inactive = isRecord(data) && data.active === false;
    if (active) changeWaiting("ask-user", 1);
    else if (inactive) changeWaiting("ask-user", -1);
  });

  pi.on("session_shutdown", () => {
    disposed = true;
    unsubscribePermissionPrompt();
    unsubscribePermissionDecision();
    unsubscribeAskUser();
  });

  function waitingCount(): number {
    let count = 0;
    for (const value of waitingReasons.values()) count += value;
    return count;
  }

  function currentStatus(): Status {
    if (waitingCount() > 0) return "waiting";
    if (idle) return "idle";
    return undefined;
  }

  async function updateZellij(): Promise<void> {
    const panes = await listPanes();
    const ownPane = panes.find((pane) => String(pane.id) === paneId.replace(/^terminal_/, ""));
    if (!ownPane || ownPane.tab_id === undefined) return;

    const status = currentStatus();
    const basePaneName = stripStatus(ownPane.title ?? "pi");
    const paneName = appendStatus(basePaneName, status);
    await action("rename-pane", "--pane-id", paneId, paneName);

    const refreshedPanes = await listPanes();
    const tabPanes = refreshedPanes.filter((pane) => pane.tab_id === ownPane.tab_id);
    const tab = await currentTab(ownPane.tab_id);
    const baseTabName = stripStatus(tab?.name ?? ownPane.tab_name ?? "tab");
    const tabStatus = aggregateTabStatus(tabPanes, paneId, status);
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
    const result = await execFileAsync("zellij", ["--session", session, ...args], {
      maxBuffer: 1024 * 1024,
    });
    return result.stdout;
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function stripStatus(name: string): string {
  return name.replace(STATUS_RE, "");
}

function appendStatus(name: string, status: Status): string {
  return status ? `${name} [${status}]` : name;
}

function statusFromTitle(title: string | undefined): Status {
  if (!title) return undefined;
  const match = title.match(/\[(idle|waiting)(?::[^\]]+)?\]$/);
  return match?.[1] as Status;
}

function aggregateTabStatus(panes: Pane[], ownPaneId: string, ownStatus: Status): Status {
  const counts = new Map<Exclude<Status, undefined>, number>();
  for (const pane of panes) {
    const id = `terminal_${pane.id}`;
    const status = id === ownPaneId || String(pane.id) === ownPaneId.replace(/^terminal_/, "")
      ? ownStatus
      : statusFromTitle(pane.title);
    if (status) counts.set(status, (counts.get(status) ?? 0) + 1);
  }
  if (counts.size === 0) return undefined;
  if (counts.size === 1) {
    const first = [...counts.entries()][0];
    if (!first) return undefined;
    const [status, count] = first;
    return count === 1 ? status : (`${status}:${count}` as Status);
  }
  return ([...counts.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([status, count]) => (count === 1 ? status : `${status}:${count}`))
    .join(", ") as Status);
}

function planReviewIsReady(ctx: ExtensionContext): boolean {
  const entries = ctx.sessionManager.getBranch() as unknown as PlanStateEntry[];
  const latest = [...entries].reverse().find((entry) =>
    entry.type === "custom" && entry.customType === PLAN_STATE_ENTRY,
  );
  if (!latest || !isRecord(latest.data)) return false;
  return latest.data.awaitingAction === true && typeof latest.data.latestPlan === "string";
}
