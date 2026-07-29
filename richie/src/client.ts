import mermaid from "mermaid";

declare global { interface Window { __RICHIE__: { id: string; token: string } } }
const context = window.__RICHIE__;
const endpoint = (name: string) => `/api/${name}/${context.id}?token=${encodeURIComponent(context.token)}`;
type Position = { offset: number; line: number; column: number };
type Range = { start: Position; end: Position };
type Operation = { id: string; kind: "delete" | "replace" | "comment"; status: string; scope: string; range?: Range; comment?: string; replacement?: string; quote?: string };
type DialogOptions = { title: string; message?: string; inputLabel?: string; confirmLabel?: string; destructive?: boolean };
const dialog = document.querySelector<HTMLDialogElement>("#richie-dialog")!;
const dialogTitle = dialog.querySelector<HTMLElement>("#richie-dialog-title")!;
const dialogMessage = dialog.querySelector<HTMLElement>("#richie-dialog-message")!;
const dialogField = dialog.querySelector<HTMLElement>("#richie-dialog-field")!;
const dialogInput = dialog.querySelector<HTMLTextAreaElement>("#richie-dialog-input")!;
const dialogConfirm = dialog.querySelector<HTMLButtonElement>("[value=confirm]")!;
const dialogCancel = dialog.querySelector<HTMLButtonElement>("[value=cancel]")!;
function modal(options: DialogOptions): Promise<string | boolean | undefined> {
  dialogTitle.textContent = options.title;
  dialogMessage.textContent = options.message ?? "";
  dialogMessage.hidden = !options.message;
  dialogField.hidden = !options.inputLabel;
  dialogField.querySelector("span")!.textContent = options.inputLabel ?? "";
  dialogInput.value = "";
  dialogConfirm.textContent = options.confirmLabel ?? "Confirm";
  dialogConfirm.classList.toggle("destructive", options.destructive === true);
  dialogCancel.hidden = options.confirmLabel === "OK";
  dialog.returnValue = "";
  dialog.showModal();
  if (options.inputLabel) dialogInput.focus(); else dialogConfirm.focus();
  return new Promise((resolve) => dialog.addEventListener("close", () => {
    if (dialog.returnValue !== "confirm") resolve(undefined);
    else resolve(options.inputLabel ? dialogInput.value : true);
  }, { once: true }));
}
function parsed(node: Node | null, offset: number): Position | undefined {
  const element = node instanceof Element ? node : node?.parentElement;
  const mapped = element?.closest("[data-md-range]");
  const value = mapped?.getAttribute("data-md-range"); if (!value || !mapped || !node) return undefined;
  const [start, end, startLine, startColumn, endLine, endColumn] = value.split(":").map(Number);
  const prefix = document.createRange();
  try { prefix.setStart(mapped, 0); prefix.setEnd(node, offset); } catch { return undefined; }
  const visibleOffset = prefix.toString().length;
  const sourceOffset = Math.min(end, start + visibleOffset);
  if (sourceOffset === end) return { offset: end, line: endLine, column: endColumn };
  const parts = prefix.toString().split("\n");
  return { offset: sourceOffset, line: startLine + parts.length - 1, column: parts.length === 1 ? startColumn + visibleOffset : parts.at(-1)!.length + 1 };
}
function selectionRange(): { start: Position; end: Position } | undefined {
  const selection = window.getSelection(); if (!selection || selection.isCollapsed) return undefined;
  const start = parsed(selection.anchorNode, selection.anchorOffset); const end = parsed(selection.focusNode, selection.focusOffset); if (!start || !end || start.offset === end.offset) return undefined; return start.offset < end.offset ? { start, end } : { start: end, end: start };
}
async function post(name: string, input: unknown): Promise<unknown> { const response = await fetch(endpoint(name), { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(input) }); const output = await response.json(); if (!response.ok) throw new Error(output.error); return output; }
async function removeOperation(id: string): Promise<unknown> { const response = await fetch(`${endpoint("operations")}/${encodeURIComponent(id)}`, { method: "DELETE" }); const output = await response.json(); if (!response.ok) throw new Error(output.error); return output; }
function sourceRange(element: Element): Range | undefined {
  const value = element.getAttribute("data-md-range"); if (!value) return undefined;
  const [start, end, startLine, startColumn, endLine, endColumn] = value.split(":").map(Number);
  return { start: { offset: start, line: startLine, column: startColumn }, end: { offset: end, line: endLine, column: endColumn } };
}
function operationTarget(operation: Operation): Element | undefined {
  if (!operation.range) return document.querySelector("#document");
  let best: Element | undefined; let bestSize = Number.POSITIVE_INFINITY;
  document.querySelectorAll<HTMLElement>("#document [data-md-range]").forEach((element) => {
    const range = sourceRange(element); if (!range || range.start.offset > operation.range!.start.offset || range.end.offset < operation.range!.end.offset) return;
    const size = range.end.offset - range.start.offset;
    if (size < bestSize) { best = element; bestSize = size; }
  });
  return best;
}
function pointAtSourceOffset(offset: number, fromEnd = false): { node: Text; offset: number } | undefined {
  const nodes: Array<{ node: Text; start: number; end: number }> = [];
  const walker = document.createTreeWalker(document.querySelector("#document")!, NodeFilter.SHOW_TEXT);
  let node: Node | null;
  while ((node = walker.nextNode())) {
    const text = node as Text; const start = parsed(text, 0)?.offset; const end = parsed(text, text.length)?.offset;
    if (start !== undefined && end !== undefined) nodes.push({ node: text, start: Math.min(start, end), end: Math.max(start, end) });
  }
  const candidates = nodes.filter((candidate) => offset >= candidate.start && offset <= candidate.end);
  const candidate = fromEnd ? candidates.at(-1) : candidates[0];
  if (!candidate) return undefined;
  return { node: candidate.node, offset: Math.max(0, Math.min(candidate.node.length, offset - candidate.start)) };
}
function domRange(operation: Operation): globalThis.Range | undefined {
  if (!operation.range) return undefined;
  const start = pointAtSourceOffset(operation.range.start.offset); const end = pointAtSourceOffset(operation.range.end.offset, true);
  if (!start || !end) return undefined;
  const range = document.createRange(); range.setStart(start.node, start.offset); range.setEnd(end.node, end.offset); return range;
}
type HighlightStore = { delete: (name: string) => void; set: (name: string, value: unknown) => void };
function reviewHighlights(): HighlightStore | undefined {
  const css = (window as unknown as { CSS?: { highlights?: HighlightStore } }).CSS;
  return css?.highlights;
}
function clearReviewPresentation(): void {
  document.querySelectorAll<HTMLElement>("[data-review-ids]").forEach((element) => { element.removeAttribute("data-review-ids"); element.removeAttribute("data-review-kind"); element.classList.remove("review-target"); });
  const highlights = reviewHighlights(); ["richie-comment", "richie-replace", "richie-delete"].forEach((name) => highlights?.delete(name));
}
function applyReviewPresentation(operations: Operation[]): void {
  clearReviewPresentation();
  const ranges = new Map<string, globalThis.Range[]>();
  operations.filter((operation) => operation.status === "open").forEach((operation) => {
    const target = operationTarget(operation); if (target) { target.classList.add("review-target"); target.dataset.reviewKind = operation.kind; target.dataset.reviewIds = `${target.dataset.reviewIds ?? ""} ${operation.id}`.trim(); }
    const range = domRange(operation); if (range) ranges.set(operation.kind, [...(ranges.get(operation.kind) ?? []), range]);
  });
  const highlights = reviewHighlights(); ranges.forEach((value, kind) => highlights?.set(`richie-${kind}`, value as unknown as never));
}
function operationSummary(operation: Operation): string {
  if (operation.kind === "replace") return `Replace with ${operation.replacement ?? "an empty value"}`;
  if (operation.kind === "delete") return operation.scope === "range" ? "Mark selected text for deletion" : `Delete ${operation.scope}`;
  return operation.comment ?? "Review this selection";
}
function renderFeedback(operations: Operation[]): void {
  const open = operations.filter((operation) => operation.status === "open");
  const count = document.querySelector<HTMLElement>("#feedback-count")!; count.textContent = `${open.length} open`;
  const container = document.querySelector<HTMLElement>("#operations")!; container.replaceChildren();
  if (!open.length) { const empty = document.createElement("p"); empty.textContent = "No feedback yet. Select text or use a block control to add some."; container.append(empty); return; }
  open.forEach((operation) => {
    const card = document.createElement("article"); card.className = "operation-card"; card.dataset.kind = operation.kind;
    const meta = document.createElement("div"); meta.className = "operation-meta"; meta.append(operation.id, document.createTextNode(`${operation.kind} · ${operation.scope}`)); card.append(meta);
    if (operation.quote) { const quote = document.createElement("q"); quote.className = "operation-quote"; quote.textContent = operation.quote; card.append(quote); }
    const detail = document.createElement("p"); detail.className = "operation-detail"; detail.textContent = operationSummary(operation); card.append(detail);
    const actions = document.createElement("div"); actions.className = "operation-actions";
    if (operation.range) { const jump = document.createElement("button"); jump.textContent = "Jump to text"; jump.addEventListener("click", () => operationTarget(operation)?.scrollIntoView({ behavior: "smooth", block: "center" })); actions.append(jump); }
    const remove = document.createElement("button"); remove.textContent = "Remove"; remove.dataset.action = "remove-operation"; remove.addEventListener("click", async () => {
      if (!await modal({ title: "Remove feedback", message: `${operation.id} will be removed from this review.`, confirmLabel: "Remove", destructive: true })) return;
      try { await removeOperation(operation.id); await refresh(); } catch (error) { await modal({ title: "Richie could not remove the feedback", message: (error as Error).message, confirmLabel: "OK" }); }
    }); actions.append(remove); card.append(actions); container.append(card);
  });
}
function renderOutline(): void {
  const container = document.querySelector<HTMLElement>("#outline-items")!; container.replaceChildren();
  document.querySelectorAll<HTMLElement>("#document h1, #document h2, #document h3").forEach((heading) => {
    const link = document.createElement("button"); link.className = "outline-link"; link.dataset.depth = heading.tagName.slice(1); link.textContent = heading.textContent ?? "Untitled section";
    link.addEventListener("click", () => heading.scrollIntoView({ behavior: "smooth", block: "start" })); container.append(link);
  });
}
let searchMatches: globalThis.Range[] = [];
let searchIndex = -1;
function clearSearchHighlights(): void { const highlights = reviewHighlights(); highlights?.delete("richie-search"); highlights?.delete("richie-search-current"); document.querySelectorAll(".search-match,.search-current").forEach((element) => element.classList.remove("search-match", "search-current")); }
function applySearchHighlights(): void {
  clearSearchHighlights(); if (!searchMatches.length) return;
  const highlights = reviewHighlights();
  if (highlights) { highlights.set("richie-search", searchMatches as unknown as never); if (searchIndex >= 0) highlights.set("richie-search-current", [searchMatches[searchIndex]] as unknown as never); }
  else searchMatches.forEach((range, index) => { const parent = range.commonAncestorContainer.parentElement; parent?.classList.add(index === searchIndex ? "search-current" : "search-match"); });
}
function updateSearch(): void {
  const input = document.querySelector<HTMLInputElement>("#document-search")!; const query = input.value.trim().toLocaleLowerCase(); searchMatches = []; searchIndex = -1;
  if (query) {
    const walker = document.createTreeWalker(document.querySelector("#document")!, NodeFilter.SHOW_TEXT);
    let node: Node | null;
    while ((node = walker.nextNode())) {
      const text = node.textContent?.toLocaleLowerCase() ?? ""; let start = 0;
      while (true) { const found = text.indexOf(query, start); if (found < 0) break; const range = document.createRange(); range.setStart(node, found); range.setEnd(node, found + query.length); searchMatches.push(range); start = found + Math.max(query.length, 1); }
    }
    if (searchMatches.length) searchIndex = 0;
  }
  const count = document.querySelector<HTMLOutputElement>("#search-count")!; count.textContent = searchMatches.length ? `${searchIndex + 1}/${searchMatches.length}` : query ? "0 matches" : ""; applySearchHighlights();
}
function moveSearch(step: number): void {
  if (!searchMatches.length) return; searchIndex = (searchIndex + step + searchMatches.length) % searchMatches.length; applySearchHighlights();
  const range = searchMatches[searchIndex]; range.commonAncestorContainer.parentElement?.scrollIntoView({ behavior: "smooth", block: "center" });
  const count = document.querySelector<HTMLOutputElement>("#search-count")!; count.textContent = `${searchIndex + 1}/${searchMatches.length}`;
}
async function refresh(): Promise<void> { const state = await fetch(endpoint("state")).then((response) => response.json()) as { operations: Operation[] }; renderFeedback(state.operations); applyReviewPresentation(state.operations); renderOutline(); }
async function renderMermaid(): Promise<void> {
  mermaid.initialize({ startOnLoad: false, securityLevel: "strict" });
  for (const [index, element] of [...document.querySelectorAll<HTMLElement>(".mermaid")].entries()) {
    try { const result = await mermaid.render(`richie-mermaid-${index}`, element.dataset.mermaid ?? ""); element.innerHTML = result.svg; result.bindFunctions?.(element); }
    catch (error) { element.insertAdjacentHTML("beforeend", `<p class="review-note">Mermaid did not render: ${(error as Error).message}</p>`); }
  }
}
function blockRange(element: Element): { start: Position; end: Position } | undefined {
  const value = element.getAttribute("data-md-range"); if (!value) return undefined;
  const [start, end, startLine, startColumn, endLine, endColumn] = value.split(":").map(Number);
  return { start: { offset: start, line: startLine, column: startColumn }, end: { offset: end, line: endLine, column: endColumn } };
}
function targetControl(label: string, scope: string, kind: string, element: Element): HTMLButtonElement {
  const button = document.createElement("button"); button.className = "richie-target"; button.textContent = label;
  button.addEventListener("mousedown", (event) => event.preventDefault());
  button.addEventListener("click", async (event) => { event.preventDefault(); event.stopPropagation();
    const selection = window.getSelection(); const selectedRange = selectionRange(); const activeRange = selectedRange ?? blockRange(element); if (!activeRange) return;
    const activeScope = selectedRange ? "range" : scope;
    const targetText = (selectedRange ? selection?.toString() : element.textContent)?.trim() ?? "";
    try { if (kind === "comment") { const comment = await modal({ title: "Add comment", inputLabel: "Comment", confirmLabel: "Add comment" }); if (typeof comment === "string" && comment) await post("operations", { kind, scope: activeScope, range: activeRange, comment }); }
      else if (kind === "replace") { const replacement = await modal({ title: "Replace text", message: `Text to replace: ${targetText}`, inputLabel: "Replacement", confirmLabel: "Replace" }); if (typeof replacement === "string") await post("operations", { kind, scope: activeScope, range: activeRange, replacement }); }
      else if (await modal({ title: `Delete ${activeScope}`, message: `Mark this ${activeScope} for deletion?`, confirmLabel: "Delete", destructive: true })) await post("operations", { kind, scope: activeScope, range: activeRange }); await refresh();
    } catch (error) { await modal({ title: "Richie could not save the review", message: (error as Error).message, confirmLabel: "OK" }); }
  }); return button;
}
type TargetAction = { label: string; kind: string; scope?: string; target?: Element };
const targetPanel = document.createElement("span"); targetPanel.className = "richie-target-menu"; document.body.append(targetPanel);
let activeTarget: Element | undefined;
let hideTimer: number | undefined;
let showTimer: number | undefined;
const cancelHandoff = (): void => {
  if (hideTimer !== undefined) window.clearTimeout(hideTimer);
  if (showTimer !== undefined) window.clearTimeout(showTimer);
  hideTimer = undefined; showTimer = undefined;
};
const hidePanel = (): void => {
  if (hideTimer !== undefined) window.clearTimeout(hideTimer);
  hideTimer = window.setTimeout(() => {
    hideTimer = undefined;
    if (!selectionRange()) targetPanel.style.display = "none";
  }, 180);
};
function positionPanel(rect: DOMRect): void {
  const width = targetPanel.offsetWidth;
  const left = Math.min(Math.max(8, rect.left), Math.max(8, window.innerWidth - width - 8));
  const below = rect.bottom + 6;
  const top = below + targetPanel.offsetHeight <= window.innerHeight - 8 ? below : Math.max(8, rect.top - targetPanel.offsetHeight - 6);
  targetPanel.style.left = `${left}px`; targetPanel.style.top = `${top}px`;
}
function showPanel(scope: string, element: Element, actions: TargetAction[], rect = element.getBoundingClientRect()): void {
  cancelHandoff(); activeTarget = element; targetPanel.replaceChildren();
  actions.forEach(({ label, kind, scope: actionScope, target }) => targetPanel.append(targetControl(label, actionScope ?? scope, kind, target ?? element)));
  targetPanel.style.display = "flex"; positionPanel(rect);
}
function targetMenu(scope: string, element: Element, actions: TargetAction[]): void {
  element.addEventListener("mouseenter", () => {
    if (selectionRange()) return;
    if (hideTimer === undefined) showPanel(scope, element, actions);
    else showTimer = window.setTimeout(() => showPanel(scope, element, actions), 200);
  });
  element.addEventListener("mouseleave", hidePanel);
}
const selectionActions: TargetAction[] = [{ label: "Comment", kind: "comment" }, { label: "Replace", kind: "replace" }, { label: "Delete", kind: "delete" }];
document.addEventListener("selectionchange", () => {
  window.setTimeout(() => {
    const range = selectionRange(); const selection = window.getSelection();
    if (range && selection?.rangeCount) showPanel("range", activeTarget ?? document.querySelector("#document")!, selectionActions, selection.getRangeAt(0).getBoundingClientRect());
    else if (!targetPanel.matches(":hover")) targetPanel.style.display = "none";
  });
});
targetPanel.addEventListener("mouseenter", cancelHandoff);
targetPanel.addEventListener("mouseleave", hidePanel);
window.addEventListener("scroll", () => { if (selectionRange()) targetPanel.style.display = "none"; }, true);
document.querySelectorAll("h1[data-md-block],h2[data-md-block],h3[data-md-block],p[data-md-block]").forEach((element) => {
  if (!element.closest("td")) targetMenu("block", element, selectionActions);
});
[...document.querySelectorAll(".mermaid-source-line,.code-source-line")].forEach((element) => targetMenu("range", element, selectionActions));
document.querySelectorAll("details[data-md-mermaid-source]").forEach((element) => targetMenu("block", element, [{ label: "Comment", kind: "comment" }]));
document.querySelectorAll("td[data-md-block]").forEach((element) => targetMenu("cell", element, [{ label: "Comment", kind: "comment" }, { label: "Clear cell", kind: "delete" }, { label: "Delete column", kind: "delete", scope: "column" }, { label: "Delete row", kind: "delete", scope: "row", target: element.closest("tr")! }]));
document.querySelector("#toolbar")!.addEventListener("click", async (event) => {
  const action = (event.target as HTMLElement).dataset.action; try {
    if (action === "search-next") { moveSearch(1); return; }
    if (action === "search-previous") { moveSearch(-1); return; }
    if (action === "finish") {
      if (!await modal({ title: "Finish review", message: "Open feedback will be exported and this tab will close.", confirmLabel: "Finish review" })) return;
      const result = await post("finish", {}) as { exported: boolean; outputPath: string | null };
      await modal({ title: "Review finished", message: result.exported ? `Review exported to ${result.outputPath}` : "No feedback was recorded. Nothing was exported.", confirmLabel: "OK" });
      window.close();
      return;
    }
    if (action === "abort") {
      if (!await modal({ title: "Abort review", message: "All open feedback will be discarded and nothing will be exported.", confirmLabel: "Abort review", destructive: true })) return;
      await post("abort", {});
      window.close();
      return;
    }
    if (action === "document-note") { const comment = await modal({ title: "Document level note", message: "This note will be added at the end.", inputLabel: "Comment", confirmLabel: "Add note" }); if (typeof comment === "string" && comment) await post("operations", { kind: "comment", scope: "document", placement: "end", comment }); await refresh(); return; }
    else { const range = selectionRange(); if (!range) throw new Error("Select text first."); if (action === "replace") { const replacement = await modal({ title: "Replace text", message: `Text to replace: ${window.getSelection()?.toString().trim() ?? ""}`, inputLabel: "Replacement", confirmLabel: "Replace" }); if (typeof replacement === "string") await post("operations", { kind: "replace", scope: "range", range, replacement }); } else if (action === "comment") { const comment = await modal({ title: "Add comment", inputLabel: "Comment", confirmLabel: "Add comment" }); if (typeof comment === "string" && comment) await post("operations", { kind: "comment", scope: "range", range, comment }); } else if (action === "delete" && await modal({ title: "Delete selected text", message: "Mark the selected text for deletion?", confirmLabel: "Delete", destructive: true })) await post("operations", { kind: "delete", scope: "range", range }); }
    await refresh();
  } catch (error) { await modal({ title: "Richie could not complete the action", message: (error as Error).message, confirmLabel: "OK" }); }
});
refresh();
renderMermaid();
document.querySelector<HTMLInputElement>("#document-search")?.addEventListener("input", updateSearch);
document.querySelector<HTMLInputElement>("#document-search")?.addEventListener("keydown", (event) => { if (event.key === "Enter") { event.preventDefault(); moveSearch(event.shiftKey ? -1 : 1); } });
