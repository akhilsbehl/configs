import mermaid from "mermaid";

declare global { interface Window { __RICHIE__: { id: string; token: string } } }
const context = window.__RICHIE__;
const endpoint = (name: string) => `/api/${name}/${context.id}?token=${encodeURIComponent(context.token)}`;
const operationEndpoint = (id: string) => `/api/operations/${context.id}/${encodeURIComponent(id)}?token=${encodeURIComponent(context.token)}`;
type Position = { offset: number; line: number; column: number };
type Range = { start: Position; end: Position };
type Operation = { id: string; kind: "delete" | "replace" | "comment"; status: string; scope: string; range?: Range; comment?: string; replacement?: string; quote?: string };
type DialogOptions = { title: string; message?: string; inputLabel?: string; inputValue?: string; confirmLabel?: string; destructive?: boolean };
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
  dialogInput.value = options.inputValue ?? "";
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
dialog.addEventListener("keydown", (event) => {
  if (event.key === "Enter" && (event.ctrlKey || event.metaKey)) { event.preventDefault(); dialogConfirm.click(); }
});
function excerpt(value: string): string {
  const compact = value.replace(/\s+/g, " ").trim();
  return compact.length > 120 ? `${compact.slice(0, 117)}…` : compact;
}
function parsed(node: Node | null, offset: number): Position | undefined {
  const element = node instanceof Element ? node : node?.parentElement;
  const sourceText = element?.closest(".md-text,code[data-md-range]");
  const mapped = sourceText?.matches("[data-md-range]") ? sourceText : sourceText?.closest("[data-md-range]");
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
async function removeOperation(id: string): Promise<unknown> { const response = await fetch(operationEndpoint(id), { method: "DELETE" }); const output = await response.json(); if (!response.ok) throw new Error(output.error); return output; }
async function patchOperation(id: string, input: unknown): Promise<unknown> { const response = await fetch(operationEndpoint(id), { method: "PATCH", headers: { "content-type": "application/json" }, body: JSON.stringify(input) }); const output = await response.json(); if (!response.ok) throw new Error(output.error); return output; }
function sourceRange(element: Element): Range | undefined {
  const value = element.getAttribute("data-md-range"); if (!value) return undefined;
  const [start, end, startLine, startColumn, endLine, endColumn] = value.split(":").map(Number);
  return { start: { offset: start, line: startLine, column: startColumn }, end: { offset: end, line: endLine, column: endColumn } };
}
function operationTarget(operation: Operation): Element | undefined {
  if (!operation.range) return undefined;
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
type HighlightConstructor = new (...ranges: globalThis.Range[]) => unknown;
function reviewHighlights(): HighlightStore | undefined {
  const css = (window as unknown as { CSS?: { highlights?: HighlightStore } }).CSS;
  return css?.highlights;
}
function makeHighlight(ranges: globalThis.Range[]): unknown {
  const constructor = (window as unknown as { Highlight?: HighlightConstructor }).Highlight;
  return constructor ? new constructor(...ranges) : undefined;
}
function clearReviewPresentation(): void {
  document.querySelectorAll<HTMLElement>("[data-review-ids]").forEach((element) => { element.removeAttribute("data-review-ids"); element.removeAttribute("data-review-kind"); element.removeAttribute("data-review-replacement"); element.removeAttribute("aria-describedby"); element.classList.remove("review-target", "review-column-target"); });
  document.querySelectorAll(".review-replacement-inline").forEach((element) => element.remove());
  const highlights = reviewHighlights(); ["richie-comment", "richie-replace", "richie-delete"].forEach((name) => highlights?.delete(name));
}
function columnTargets(operation: Operation): HTMLElement[] {
  const target = operationTarget(operation)?.closest("td");
  const table = target?.closest("table");
  if (!target || !table) return [];
  const index = [...target.parentElement!.children].indexOf(target);
  return [...table.querySelectorAll("tr")].map((row) => row.children.item(index)).filter((cell): cell is HTMLElement => cell instanceof HTMLElement);
}
function applyReviewPresentation(operations: Operation[]): void {
  clearReviewPresentation();
  const ranges = new Map<string, globalThis.Range[]>();
  const inlineReplacements: Array<{ operation: Operation; range: globalThis.Range }> = [];
  operations.filter((operation) => operation.status === "open").forEach((operation) => {
    if (operation.scope === "column") {
      columnTargets(operation).forEach((target) => { target.classList.add("review-column-target"); target.dataset.reviewKind = operation.kind; target.dataset.reviewIds = `${target.dataset.reviewIds ?? ""} ${operation.id}`.trim(); });
    } else {
      const target = operationTarget(operation); if (target) {
        if (operation.scope !== "range") target.classList.add("review-target");
        target.dataset.reviewKind = operation.kind;
        target.dataset.reviewIds = `${target.dataset.reviewIds ?? ""} ${operation.id}`.trim();
        target.setAttribute("aria-describedby", [...new Set(`${target.getAttribute("aria-describedby") ?? ""} feedback-${operation.id}`.trim().split(/\\s+/))].join(" "));
        if (operation.kind === "replace" && operation.replacement && operation.scope !== "range") target.dataset.reviewReplacement = operation.replacement;
      }
    }
    if (operation.scope === "range") {
      const range = domRange(operation); if (range) {
        ranges.set(operation.kind, [...(ranges.get(operation.kind) ?? []), range]);
        if (operation.kind === "replace" && operation.replacement) inlineReplacements.push({ operation, range });
      }
    }
  });
  const highlights = reviewHighlights(); ranges.forEach((value, kind) => { const highlight = makeHighlight(value); if (highlight) highlights?.set(`richie-${kind}`, highlight); });
  inlineReplacements.forEach(({ operation, range }) => {
    const replacement = document.createElement("span"); replacement.className = "review-replacement-inline"; replacement.dataset.operationId = operation.id;
    replacement.textContent = ` → ${operation.replacement}`; replacement.id = `replacement-${operation.id}`;
    const insertion = range.cloneRange(); insertion.collapse(false); insertion.insertNode(replacement);
  });
}
function operationSummary(operation: Operation): string {
  if (operation.kind === "replace") return `Replace with ${operation.replacement ?? "an empty value"}`;
  if (operation.kind === "delete") {
    if (operation.scope === "range") return "Mark the selected text for deletion";
    if (operation.scope === "media") return "Delete this image";
    if (operation.scope === "cell") return "Clear this cell";
    if (operation.scope === "row") return "Delete this row";
    if (operation.scope === "column") return "Delete this column";
    return "Delete this block";
  }
  return operation.comment ?? "Review this selection";
}
function renderFeedback(operations: Operation[]): void {
  const open = operations.filter((operation) => operation.status === "open");
  const count = document.querySelector<HTMLElement>("#feedback-count")!; count.textContent = `${open.length} open`;
  const container = document.querySelector<HTMLElement>("#operations")!; container.replaceChildren();
  if (!open.length) { const empty = document.createElement("p"); empty.textContent = "No feedback yet. Select text or use a block control to add some."; container.append(empty); return; }
  open.forEach((operation) => {
    const card = document.createElement("article"); card.className = "operation-card"; card.dataset.kind = operation.kind; card.id = `feedback-${operation.id}`; card.tabIndex = -1;
    const meta = document.createElement("div"); meta.className = "operation-meta"; meta.append(operation.id, document.createTextNode(`${operation.kind} · ${operation.scope}`)); card.append(meta);
    if (operation.quote) { const quote = document.createElement("q"); quote.className = "operation-quote"; quote.textContent = operation.quote; card.append(quote); }
    const detail = document.createElement("p"); detail.className = "operation-detail"; detail.textContent = operationSummary(operation); card.append(detail);
    const actions = document.createElement("div"); actions.className = "operation-actions";
    if (operation.range) { const jump = document.createElement("button"); jump.textContent = "Jump to text"; jump.addEventListener("click", () => operationTarget(operation)?.scrollIntoView({ behavior: "smooth", block: "center" })); actions.append(jump); }
    if (operation.kind !== "delete") {
      const edit = document.createElement("button"); edit.textContent = "Edit";
      edit.addEventListener("click", async () => {
        const isComment = operation.kind === "comment";
        const value = await modal({ title: isComment ? "Edit comment" : operation.scope === "media" ? "Edit image replacement" : "Edit replacement", inputLabel: isComment ? "Comment" : operation.scope === "media" ? "Replacement Markdown" : "Replacement", inputValue: (isComment ? operation.comment : operation.replacement) ?? "", confirmLabel: "Save" });
        if (value === undefined) return;
        if (typeof value !== "string" || !value.trim()) { await modal({ title: isComment ? "Comment is empty" : "Replacement is empty", message: "Type a value, or cancel the dialog.", confirmLabel: "OK" }); return; }
        try { await patchOperation(operation.id, isComment ? { comment: value } : { replacement: value }); await refresh(); }
        catch (error) { await modal({ title: "Richie could not update the feedback", message: (error as Error).message, confirmLabel: "OK" }); }
      });
      actions.append(edit);
    }
    const remove = document.createElement("button"); remove.textContent = "Remove"; remove.dataset.action = "remove-operation"; remove.addEventListener("click", async () => {
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
  if (highlights) {
    const all = makeHighlight(searchMatches); if (all) highlights.set("richie-search", all);
    if (searchIndex >= 0) { const current = makeHighlight([searchMatches[searchIndex]]); if (current) highlights.set("richie-search-current", current); }
  } else searchMatches.forEach((range, index) => range.commonAncestorContainer.parentElement?.classList.add(index === searchIndex ? "search-current" : "search-match"));
}
type TextEntry = { node: Text; start: number };
function collectDocumentText(): { entries: TextEntry[]; lowered: string } {
  const entries: TextEntry[] = []; let full = "";
  const walker = document.createTreeWalker(document.querySelector("#document")!, NodeFilter.SHOW_TEXT);
  let node: Node | null;
  while ((node = walker.nextNode())) {
    if (node.parentElement?.closest("[hidden]")) continue;
    entries.push({ node: node as Text, start: full.length }); full += node.textContent ?? "";
  }
  return { entries, lowered: full.toLocaleLowerCase() };
}
function locateDocumentText(entries: TextEntry[], index: number, atEnd: boolean): { node: Text; offset: number } | undefined {
  for (const entry of entries) {
    const limit = entry.start + entry.node.length;
    if ((atEnd ? index <= limit : index < limit) && index >= entry.start) return { node: entry.node, offset: index - entry.start };
  }
  return undefined;
}
function updateSearch(): void {
  const input = document.querySelector<HTMLInputElement>("#document-search")!; const query = input.value.trim().toLocaleLowerCase(); searchMatches = []; searchIndex = -1;
  if (query) {
    const { entries, lowered } = collectDocumentText();
    let start = 0;
    while (true) {
      const found = lowered.indexOf(query, start); if (found < 0) break;
      const from = locateDocumentText(entries, found, false); const to = locateDocumentText(entries, found + query.length, true);
      if (from && to) { const range = document.createRange(); range.setStart(from.node, from.offset); range.setEnd(to.node, to.offset); searchMatches.push(range); }
      start = found + Math.max(query.length, 1);
    }
  }
  if (searchMatches.length) searchIndex = 0;
  const count = document.querySelector<HTMLOutputElement>("#search-count")!; count.textContent = searchMatches.length ? `${searchIndex + 1}/${searchMatches.length}` : query ? "0 matches" : ""; applySearchHighlights();
}
function moveSearch(step: number): void {
  if (!searchMatches.length) return;
  searchIndex = (searchIndex + step + searchMatches.length) % searchMatches.length;
  applySearchHighlights();
  searchMatches[searchIndex].startContainer.parentElement?.scrollIntoView({ behavior: "smooth", block: "center" });
  document.querySelector<HTMLOutputElement>("#search-count")!.textContent = `${searchIndex + 1}/${searchMatches.length}`;
}
async function refresh(): Promise<void> { const state = await fetch(endpoint("state")).then((response) => response.json()) as { operations: Operation[] }; renderFeedback(state.operations); applyReviewPresentation(state.operations); renderOutline(); }
function revealFeedback(ids: string[]): void {
  const cards = ids.map((id) => document.getElementById(`feedback-${id}`)).filter((card): card is HTMLElement => card instanceof HTMLElement);
  if (!cards.length) return;
  const first = cards[0]; first.scrollIntoView({ behavior: "smooth", block: "nearest" }); first.focus({ preventScroll: true });
  cards.forEach((card) => { card.classList.remove("feedback-focus"); void card.offsetWidth; card.classList.add("feedback-focus"); });
  document.querySelectorAll<HTMLElement>("#document [data-review-ids]").forEach((element) => {
    if (!ids.some((id) => (element.dataset.reviewIds ?? "").split(/\\s+/).includes(id))) return;
    element.classList.remove("backlink-active"); void element.offsetWidth; element.classList.add("backlink-active");
    window.setTimeout(() => element.classList.remove("backlink-active"), 1800);
  });
}
document.querySelector("#document")!.addEventListener("click", (event) => {
  const target = (event.target as Element).closest<HTMLElement>("[data-review-ids]");
  if (!target) return;
  const ids = (target.dataset.reviewIds ?? "").split(/\\s+/).filter(Boolean);
  if (ids.length) { event.preventDefault(); revealFeedback(ids); }
});
async function renderMermaid(): Promise<void> {
  mermaid.initialize({ startOnLoad: false, securityLevel: "strict" });
  for (const [index, element] of [...document.querySelectorAll<HTMLElement>(".mermaid")].entries()) {
    try { const result = await mermaid.render(`richie-mermaid-${index}`, element.dataset.mermaid ?? ""); element.innerHTML = result.svg; result.bindFunctions?.(element); }
    catch (error) {
      const note = document.createElement("p");
      note.className = "review-note";
      note.textContent = `Mermaid did not render: ${(error as Error).message}`;
      element.append(note);
      const source = element.nextElementSibling;
      if (source instanceof HTMLDetailsElement && source.matches("[data-md-mermaid-source]")) {
        source.open = true;
        const summary = source.querySelector("summary");
        if (summary) summary.textContent = "Mermaid source (render failed)";
      }
    }
  }
}
function blockRange(element: Element): { start: Position; end: Position } | undefined {
  const value = element.getAttribute("data-md-range"); if (!value) return undefined;
  const [start, end, startLine, startColumn, endLine, endColumn] = value.split(":").map(Number);
  return { start: { offset: start, line: startLine, column: startColumn }, end: { offset: end, line: endLine, column: endColumn } };
}
async function createOperation(kind: string, scope: string, range: Range | undefined, targetText: string): Promise<void> {
  try {
    if (kind === "comment") {
      const comment = await modal({ title: "Add comment", message: targetText.trim() ? `Commenting on: ${excerpt(targetText)}` : undefined, inputLabel: "Comment", confirmLabel: "Add comment" });
      if (comment === undefined) return;
      if (typeof comment !== "string" || !comment.trim()) { await modal({ title: "Comment is empty", message: "Type a comment, or cancel the dialog.", confirmLabel: "OK" }); return; }
      await post("operations", { kind, scope, range, comment });
    } else if (kind === "replace") {
      const replacement = await modal({ title: scope === "media" ? "Replace image" : "Replace text", message: `Text to replace: ${excerpt(targetText)}`, inputLabel: scope === "media" ? "Replacement Markdown" : "Replacement", confirmLabel: "Replace" });
      if (replacement === undefined) return;
      if (typeof replacement !== "string" || !replacement.trim()) { await modal({ title: "Replacement is empty", message: "Type the replacement text, or use Delete to remove the text instead.", confirmLabel: "OK" }); return; }
      await post("operations", { kind, scope, range, replacement });
    } else {
      await post("operations", { kind, scope, range });
    }
    window.getSelection()?.removeAllRanges();
    hideNow();
    await refresh();
  } catch (error) { await modal({ title: "Richie could not save the review", message: (error as Error).message, confirmLabel: "OK" }); }
}
function targetControl(label: string, scope: string, kind: string, element: Element | undefined): HTMLButtonElement {
  const button = document.createElement("button"); button.className = "richie-target"; button.textContent = label;
  button.addEventListener("mousedown", (event) => event.preventDefault());
  button.addEventListener("click", (event) => {
    event.preventDefault(); event.stopPropagation();
    if (element) { const range = blockRange(element); if (range) void createOperation(kind, scope, range, element.getAttribute("data-md-media-source") ?? element.textContent ?? ""); }
    else { const range = selectionRange(); if (range) void createOperation(kind, "range", range, window.getSelection()?.toString() ?? ""); }
  });
  return button;
}
type TargetAction = { label: string; kind: string; scope?: string; target?: Element };
const targetPanel = document.createElement("span"); targetPanel.className = "richie-target-menu"; document.body.append(targetPanel);
let activeTarget: Element | undefined;
let panelAnchor: (() => DOMRect | undefined) | undefined;
let hideTimer: number | undefined;
let showTimer: number | undefined;
const cancelHandoff = (): void => {
  if (hideTimer !== undefined) window.clearTimeout(hideTimer);
  if (showTimer !== undefined) window.clearTimeout(showTimer);
  hideTimer = undefined; showTimer = undefined;
};
function hideNow(): void {
  cancelHandoff();
  targetPanel.style.display = "none";
  activeTarget?.classList.remove("richie-hover");
  activeTarget = undefined;
  panelAnchor = undefined;
}
const hidePanel = (): void => {
  if (hideTimer !== undefined) window.clearTimeout(hideTimer);
  hideTimer = window.setTimeout(() => {
    hideTimer = undefined;
    if (!selectionRange()) hideNow();
  }, 180);
};
function positionPanel(rect: DOMRect): void {
  const width = targetPanel.offsetWidth;
  const left = Math.min(Math.max(8, rect.left), Math.max(8, window.innerWidth - width - 8));
  const below = rect.bottom + 6;
  const top = below + targetPanel.offsetHeight <= window.innerHeight - 8 ? below : Math.max(8, rect.top - targetPanel.offsetHeight - 6);
  targetPanel.style.left = `${left}px`; targetPanel.style.top = `${top}px`;
}
function showPanel(scope: string, element: Element | undefined, actions: TargetAction[], rect = element?.getBoundingClientRect()): void {
  if (!rect) return;
  cancelHandoff();
  activeTarget?.classList.remove("richie-hover");
  activeTarget = element;
  element?.classList.add("richie-hover");
  targetPanel.replaceChildren();
  actions.forEach(({ label, kind, scope: actionScope, target }) => targetPanel.append(targetControl(label, actionScope ?? scope, kind, element ? (target ?? element) : undefined)));
  targetPanel.style.display = "flex"; positionPanel(rect);
  panelAnchor = element
    ? () => element.getBoundingClientRect()
    : () => { const selection = window.getSelection(); return selection?.rangeCount && !selection.isCollapsed ? selection.getRangeAt(0).getBoundingClientRect() : undefined; };
}
function targetMenu(scope: string, element: Element, actions: TargetAction[]): void {
  element.addEventListener("mouseenter", () => {
    if (selectionRange()) return;
    cancelHandoff();
    showTimer = window.setTimeout(() => { showTimer = undefined; showPanel(scope, element, actions); }, 220);
  });
  element.addEventListener("mouseleave", () => {
    if (showTimer !== undefined) { window.clearTimeout(showTimer); showTimer = undefined; }
    hidePanel();
  });
}
const selectionActions: TargetAction[] = [{ label: "Comment", kind: "comment" }, { label: "Replace", kind: "replace" }, { label: "Delete", kind: "delete" }];
const mediaActions: TargetAction[] = [{ label: "Comment", kind: "comment" }, { label: "Replace", kind: "replace" }, { label: "Delete", kind: "delete" }];
document.addEventListener("selectionchange", () => {
  window.setTimeout(() => {
    const range = selectionRange(); const selection = window.getSelection();
    if (range && selection?.rangeCount) showPanel("range", undefined, selectionActions, selection.getRangeAt(0).getBoundingClientRect());
    else if (!targetPanel.matches(":hover")) hideNow();
  });
});
document.querySelector("#document")!.addEventListener("contextmenu", (event) => {
  if (selectionRange()) event.preventDefault();
});
targetPanel.addEventListener("mouseenter", cancelHandoff);
targetPanel.addEventListener("mouseleave", hidePanel);
window.addEventListener("scroll", () => {
  if (targetPanel.style.display === "none" || !panelAnchor) return;
  const rect = panelAnchor();
  if (rect && rect.bottom > 0 && rect.top < window.innerHeight) positionPanel(rect); else hideNow();
}, true);
document.addEventListener("keydown", (event) => {
  if (dialog.open || event.ctrlKey || event.metaKey || event.altKey) return;
  const target = event.target as HTMLElement | null;
  if (target?.closest("input,textarea,select,[contenteditable=true]")) return;
  if (event.key === "Escape") { event.preventDefault(); hideNow(); return; }
  const kind = event.key === "c" ? "comment" : event.key === "r" ? "replace" : event.key === "d" ? "delete" : undefined;
  if (!kind) return;
  const range = selectionRange(); if (!range) return;
  event.preventDefault();
  void createOperation(kind, "range", range, window.getSelection()?.toString() ?? "");
});
document.querySelectorAll("h1[data-md-block],h2[data-md-block],h3[data-md-block],p[data-md-block],ul[data-md-block],ol[data-md-block],blockquote[data-md-block],pre[data-md-block]").forEach((element) => {
  if (element.closest("td")) return;
  const list = element.matches("p") ? element.closest("ul[data-md-block],ol[data-md-block]") : null;
  const actions = list ? [...selectionActions, { label: "Delete list", kind: "delete", scope: "block", target: list }] : selectionActions;
  targetMenu("block", element, actions);
});
[...document.querySelectorAll(".mermaid-source-line,.code-source-line,.math-source-line")].forEach((element) => targetMenu("range", element, selectionActions));
document.querySelectorAll("details[data-md-mermaid-source]").forEach((element) => targetMenu("block", element, [{ label: "Comment", kind: "comment" }]));
document.querySelectorAll("td[data-md-block]").forEach((element) => targetMenu("cell", element, [{ label: "Comment", kind: "comment" }, { label: "Replace", kind: "replace" }, { label: "Clear cell", kind: "delete" }, { label: "Delete column", kind: "delete", scope: "column" }, { label: "Delete row", kind: "delete", scope: "row", target: element.closest("tr")! }]));
document.querySelectorAll("[data-md-media]").forEach((element) => targetMenu("media", element, mediaActions));
document.querySelectorAll(".math-target").forEach((element) => targetMenu("range", element, selectionActions));
document.querySelector("#toolbar")!.addEventListener("click", async (event) => {
  const action = (event.target as HTMLElement).dataset.action; if (!action) return;
  try {
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
    if (action === "document-note") {
      const comment = await modal({ title: "Document level note", message: "This note will be added at the top of the commented copy.", inputLabel: "Comment", confirmLabel: "Add note" });
      if (comment === undefined) return;
      if (typeof comment !== "string" || !comment.trim()) { await modal({ title: "Comment is empty", message: "Type a comment, or cancel the dialog.", confirmLabel: "OK" }); return; }
      await post("operations", { kind: "comment", scope: "document", placement: "start", comment });
      await refresh();
    }
  } catch (error) { await modal({ title: "Richie could not complete the action", message: (error as Error).message, confirmLabel: "OK" }); }
});
refresh();
renderMermaid();
document.querySelectorAll<HTMLElement>("[data-md-media]").forEach((media) => {
  const image = media.querySelector<HTMLImageElement>("img");
  const fallback = media.querySelector<HTMLElement>(".media-fallback");
  if (!image || !fallback) return;
  const loaded = (): void => { media.dataset.mediaState = "loaded"; image.hidden = false; fallback.hidden = true; };
  const failed = (): void => { media.dataset.mediaState = "failed"; image.hidden = true; fallback.hidden = false; };
  image.addEventListener("load", loaded);
  image.addEventListener("error", failed);
  if (image.complete) {
    if (image.naturalWidth > 0) loaded(); else failed();
  }
});
document.querySelectorAll<HTMLButtonElement>("[data-action=search-next],[data-action=search-previous]").forEach((button) => button.addEventListener("click", () => moveSearch(button.dataset.action === "search-next" ? 1 : -1)));
document.querySelector<HTMLInputElement>("#document-search")?.addEventListener("input", updateSearch);
document.querySelector<HTMLInputElement>("#document-search")?.addEventListener("keydown", (event) => {
  const input = event.target as HTMLInputElement;
  if (event.key === "Enter") { event.preventDefault(); moveSearch(event.shiftKey ? -1 : 1); }
  if (event.key === "Escape") { event.preventDefault(); input.value = ""; updateSearch(); input.blur(); }
});
