import { createHash, randomUUID } from "node:crypto";
import { access, readFile, rename, writeFile } from "node:fs/promises";
import { constants } from "node:fs";
import { commentedPath, reviewSidecarPath } from "./paths.js";
import type { ReviewOperation, ReviewState } from "./types.js";

export const sha256 = (value: string): string => createHash("sha256").update(value).digest("hex");

export async function assertMarkdownFile(sourcePath: string): Promise<string> {
  if (!sourcePath.endsWith(".md")) throw new Error("Richie accepts Markdown files ending in .md");
  await access(sourcePath, constants.R_OK | constants.W_OK);
  return readFile(sourcePath, "utf8");
}

export function newState(sourcePath: string, source: string): ReviewState {
  return { schemaVersion: 1, source: sourcePath, sourceSha256: sha256(source), createdAt: new Date().toISOString(), operations: [] };
}

export async function readState(sidecarPath: string): Promise<ReviewState | undefined> {
  try { return JSON.parse(await readFile(sidecarPath, "utf8")) as ReviewState; }
  catch (error: unknown) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") return undefined;
    throw error;
  }
}

export async function writeState(sidecarPath: string, state: ReviewState): Promise<void> {
  const temporary = `${sidecarPath}.${randomUUID()}.tmp`;
  await writeFile(temporary, `${JSON.stringify(state, null, 2)}\n`, { mode: 0o600 });
  await rename(temporary, sidecarPath);
}

export async function nextCommentedPath(sourcePath: string): Promise<string> {
  for (let attempt = 1; ; attempt += 1) {
    const candidate = commentedPath(sourcePath, attempt);
    try { await access(candidate); } catch { return candidate; }
  }
}

function marker(operation: ReviewOperation): string {
  const id = `[${operation.id}]`;
  if (operation.scope === "document") return `<<ASB: ${id} ${operation.comment ?? "Document note."}>>`;
  if (operation.scope === "row") return `<<ASB: ${id} Delete this table row.>>`;
  if (operation.scope === "column") return `<<ASB: ${id} Delete this table column.>>`;
  if (operation.kind === "replace") return `<<ASB: ${id} Replace ${JSON.stringify(operation.quote ?? "selection")} with ${JSON.stringify(operation.replacement ?? "")}.>>`;
  if (operation.kind === "delete") return `<<ASB: ${id} Delete the preceding selected text.>>`;
  return `<<ASB: ${id} ${operation.comment ?? "Review this."}>>`;
}

export function renderCommentedMarkdown(source: string, state: ReviewState): string {
  const ranged = state.operations.filter((operation) => operation.status === "open" && operation.range)
    .sort((a, b) => (b.range?.end.offset ?? 0) - (a.range?.end.offset ?? 0));
  let output = source;
  for (const operation of ranged) {
    const offset = operation.range!.end.offset;
    output = `${output.slice(0, offset)} ${marker(operation)}${output.slice(offset)}`;
  }
  const opening = state.operations.filter((operation) => operation.status === "open" && operation.scope === "document" && operation.placement === "start").map(marker);
  const closing = state.operations.filter((operation) => operation.status === "open" && operation.scope === "document" && operation.placement !== "start").map(marker);
  return [...opening, output, ...closing].filter(Boolean).join("\n\n");
}

export { reviewSidecarPath };
