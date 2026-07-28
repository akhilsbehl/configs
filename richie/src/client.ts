import mermaid from "mermaid";

declare global { interface Window { __RICHIE__: { id: string; token: string } } }
const context = window.__RICHIE__;
const endpoint = (name: string) => `/api/${name}/${context.id}?token=${encodeURIComponent(context.token)}`;
type Position = { offset: number; line: number; column: number };
type Operation = { id: string; kind: string; comment?: string; replacement?: string; quote?: string };
function parsed(element: Element | null, offset: number): Position | undefined {
  const value = element?.closest("[data-md-range]")?.getAttribute("data-md-range"); if (!value) return undefined;
  const [start, end, startLine, startColumn, endLine, endColumn] = value.split(":").map(Number); const text = element?.textContent ?? "";
  const atEnd = offset >= text.length; return { offset: (atEnd ? end : start) + offset, line: atEnd ? endLine : startLine, column: atEnd ? endColumn : startColumn + offset };
}
function selectionRange(): { start: Position; end: Position } | undefined {
  const selection = window.getSelection(); if (!selection || selection.isCollapsed) return undefined;
  const startElement = selection.anchorNode?.parentElement ?? null; const endElement = selection.focusNode?.parentElement ?? null;
  const start = parsed(startElement, selection.anchorOffset); const end = parsed(endElement, selection.focusOffset); if (!start || !end || start.offset >= end.offset) return undefined; return { start, end };
}
async function post(name: string, input: unknown): Promise<unknown> { const response = await fetch(endpoint(name), { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(input) }); const output = await response.json(); if (!response.ok) throw new Error(output.error); return output; }
async function refresh(): Promise<void> { const state = await fetch(endpoint("state")).then((response) => response.json()) as { operations: Operation[] }; document.querySelector("#operations")!.innerHTML = state.operations.map((operation) => `<p><code>${operation.id}</code> ${operation.kind}: ${operation.replacement ?? operation.comment ?? operation.quote ?? ""}</p>`).join("") || "<p>None</p>"; }
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
  button.addEventListener("click", async (event) => { event.preventDefault(); event.stopPropagation(); const range = blockRange(element); if (!range) return;
    try { if (kind === "comment") { const comment = prompt("Comment:"); if (comment) await post("operations", { kind, scope, range, comment }); }
      else if (kind === "replace") { const replacement = prompt("Replacement:"); if (replacement !== null) await post("operations", { kind, scope, range, replacement }); }
      else if (confirm(`Mark this ${scope} for deletion?`)) await post("operations", { kind, scope, range }); await refresh();
    } catch (error) { alert((error as Error).message); }
  }); return button;
}
document.querySelectorAll("h1[data-md-block],h2[data-md-block],h3[data-md-block],details[data-md-mermaid-source]").forEach((element) => element.append(targetControl("Comment", "block", "comment", element)));
[...document.querySelectorAll(".md-text-range,.mermaid-source-line")].forEach((element) => { element.append(targetControl("Comment", "range", "comment", element)); element.append(targetControl("Replace", "range", "replace", element)); element.append(targetControl("Delete", "range", "delete", element)); });
document.querySelectorAll("td[data-md-block]").forEach((element) => { element.append(targetControl("Comment", "cell", "comment", element)); element.append(targetControl("Clear", "cell", "delete", element)); element.append(targetControl("Delete column", "column", "delete", element)); });
document.querySelectorAll("tr[data-md-block]").forEach((element) => element.append(targetControl("Delete row", "row", "delete", element)));
document.querySelector("#toolbar")!.addEventListener("click", async (event) => {
  const action = (event.target as HTMLElement).dataset.action; try {
    if (action === "finish") {
      if (!confirm("Finish this review? Open feedback will be exported and this tab will close.")) return;
      const result = await post("finish", {}) as { exported: boolean; outputPath: string | null };
      alert(result.exported ? `Review exported to ${result.outputPath}` : "No feedback was recorded. Nothing was exported.");
      window.close();
      return;
    }
    if (action === "abort") {
      if (!confirm("Abort this review? All open feedback will be discarded and nothing will be exported.")) return;
      await post("abort", {});
      window.close();
      return;
    }
    if (action === "opening" || action === "closing") { const comment = prompt("Document note:"); if (comment) await post("operations", { kind: "comment", scope: "document", placement: action === "opening" ? "start" : "end", comment }); }
    else { const range = selectionRange(); if (!range) throw new Error("Select text first."); if (action === "replace") { const replacement = prompt("Replacement:"); if (replacement !== null) await post("operations", { kind: "replace", scope: "range", range, replacement }); } else if (action === "comment") { const comment = prompt("Comment:"); if (comment) await post("operations", { kind: "comment", scope: "range", range, comment }); } else if (action === "delete" && confirm("Mark selected text for deletion?")) await post("operations", { kind: "delete", scope: "range", range }); }
    await refresh();
  } catch (error) { alert((error as Error).message); }
});
refresh();
renderMermaid();
