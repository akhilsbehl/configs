import { createHash, randomUUID } from "node:crypto";
import { access, readFile, rename, writeFile } from "node:fs/promises";
import { constants } from "node:fs";
import { commentedPath, reviewSidecarPath } from "./paths.js";
import { parseMarkdown } from "./render.js";
import type { ReviewOperation, ReviewState } from "./types.js";

type MarkdownNode = {
  type: string;
  children?: MarkdownNode[];
  position?: { start: { offset: number }; end: { offset: number } };
};

export const sha256 = (value: string): string => createHash("sha256").update(value).digest("hex");

export async function assertMarkdownFile(sourcePath: string): Promise<string> {
  if (!sourcePath.endsWith(".md")) throw new Error("Richie accepts Markdown files ending in .md");
  await access(sourcePath, constants.R_OK);
  return readFile(sourcePath, "utf8");
}

export function newState(sourcePath: string, source: string): ReviewState {
  return { schemaVersion: 1, source: sourcePath, sourceSha256: sha256(source), createdAt: new Date().toISOString(), operations: [] };
}

export function hasOpenOperations(state: ReviewState): boolean {
  return state.operations.some((operation) => operation.status === "open");
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
  const quote = JSON.stringify(operation.quote ?? "selected text");
  if (operation.scope === "document") return `<<ASB: ${id} ${operation.comment ?? "Document note."}>>`;
  if (operation.scope === "row") return `<<ASB: ${id} Delete the table row selected from ${quote}.>>`;
  if (operation.scope === "column") return `<<ASB: ${id} Delete the table column selected from ${quote}.>>`;
  if (operation.scope === "cell" && operation.kind === "delete") return `<<ASB: ${id} Clear the table cell ${quote}.>>`;
  if (operation.kind === "replace") return `<<ASB: ${id} Replace ${quote} with ${JSON.stringify(operation.replacement ?? "")}.>>`;
  if (operation.kind === "delete") return `<<ASB: ${id} Delete ${operation.scope === "block" ? "the block " : ""}${quote}.>>`;
  if (operation.quote) return `<<ASB: ${id} Comment on ${operation.scope === "range" ? "" : `${operation.scope} `}${quote}: ${operation.comment ?? "Review this."}>>`;
  return `<<ASB: ${id} ${operation.comment ?? "Review this."}>>`;
}

function walk(node: MarkdownNode, type: string, matches: MarkdownNode[] = []): MarkdownNode[] {
  if (node.type === type) matches.push(node);
  for (const child of node.children ?? []) walk(child, type, matches);
  return matches;
}

function contains(node: MarkdownNode, operation: ReviewOperation): boolean {
  return Boolean(node.position && operation.range && node.position.start.offset <= operation.range.start.offset && node.position.end.offset >= operation.range.end.offset);
}

function codeMarkerPlacement(source: string, node: MarkdownNode, operation: ReviewOperation): { offset: number; text: string } {
  const start = node.position!.start.offset;
  const lineStart = source.lastIndexOf("\n", start - 1) + 1;
  const lineEnd = source.indexOf("\n", start);
  const openingLine = source.slice(lineStart, lineEnd < 0 ? source.length : lineEnd);
  const fence = openingLine.search(/[`~]{3,}/);
  const prefix = fence < 0 ? "" : openingLine.slice(0, fence);
  return { offset: node.position!.end.offset, text: `\n${prefix}${marker(operation)}` };
}

function columnMarkerPlacements(source: string, root: MarkdownNode, operation: ReviewOperation): Array<{ offset: number; text: string }> {
  const table = walk(root, "table").find((candidate) => contains(candidate, operation));
  if (!table) return [];
  const rows = (table.children ?? []).filter((candidate) => candidate.type === "tableRow");
  const column = rows.find((row) => (row.children ?? []).some((cell) => contains(cell, operation)))?.children?.findIndex((cell) => contains(cell, operation));
  if (column === undefined || column < 0) return [];
  return rows.flatMap((row) => {
    const cell = row.children?.[column];
    if (!cell?.position) return [];
    const closingFence = source.lastIndexOf("|", cell.position.end.offset - 1);
    return [{ offset: closingFence >= cell.position.start.offset ? closingFence : cell.position.end.offset, text: ` ${marker(operation)}` }];
  });
}

export function renderCommentedMarkdown(source: string, state: ReviewState): string {
  const root = parseMarkdown(source) as MarkdownNode;
  const codeBlocks = walk(root, "code");
  const insertions = state.operations.filter((operation) => operation.status === "open" && operation.range).flatMap((operation) => {
    if (operation.scope === "column") {
      const placements = columnMarkerPlacements(source, root, operation);
      if (placements.length) return placements;
    }
    const codeBlock = codeBlocks.find((candidate) => contains(candidate, operation));
    if (codeBlock) return [codeMarkerPlacement(source, codeBlock, operation)];
    return [{ offset: operation.range!.end.offset, text: ` ${marker(operation)}` }];
  }).sort((a, b) => b.offset - a.offset);
  let output = source;
  for (const insertion of insertions) {
    output = `${output.slice(0, insertion.offset)}${insertion.text}${output.slice(insertion.offset)}`;
  }
  const opening = state.operations.filter((operation) => operation.status === "open" && operation.scope === "document" && operation.placement === "start").map(marker);
  return [...opening, output].filter(Boolean).join("\n\n");
}

export { reviewSidecarPath };
