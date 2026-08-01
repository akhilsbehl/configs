import { unified } from "unified";
import hljs from "highlight.js";
import remarkGfm from "remark-gfm";
import remarkParse from "remark-parse";
import remarkMath from "remark-math";
import katex from "katex";

type Node = { type: string; value?: string; depth?: number; url?: string; title?: string | null; alt?: string; identifier?: string; label?: string; lang?: string | null; checked?: boolean | null; ordered?: boolean | null; align?: Array<string | null>; children?: Node[]; position?: { start: Position; end: Position } };
type Position = { line: number; column: number; offset: number };
export type RenderOptions = { localImageUrl?: (path: string) => string };

const escape = (value: string): string => value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
const slug = (value: string): string => value.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "") || "section";
hljs.registerLanguage("mermaid", (language) => ({
  name: "Mermaid",
  case_insensitive: true,
  keywords: "graph flowchart sequenceDiagram classDiagram stateDiagram erDiagram journey gantt pie quadrantChart requirementDiagram gitGraph mindmap timeline subgraph end direction TB TD BT RL LR",
  contains: [
    language.COMMENT("%%", "$"),
    language.QUOTE_STRING_MODE,
    { scope: "operator", begin: /-->|---|-\.-|==>|==|--/ },
    { scope: "title", begin: /[A-Za-z_][\w-]*(?=\s*[\[(\{])/ },
  ],
}));

export function parseMarkdown(source: string): Node {
  return unified().use(remarkParse).use(remarkGfm).use(remarkMath).parse(source) as unknown as Node;
}

export function renderReviewHtml(source: string, options: RenderOptions = {}): string {
  const root = parseMarkdown(source);
  const definitions = new Map<string, Node>();
  const collectDefinitions = (node: Node): void => {
    if (node.type === "definition" && node.identifier) definitions.set(node.identifier, node);
    for (const child of node.children ?? []) collectDefinitions(child);
  };
  collectDefinitions(root);
  const headings: string[] = [];
  let block = 0;
  const range = (node: Node): string => {
    if (!node.position) return "";
    const { start, end } = node.position;
    return ` data-md-range="${start.offset}:${end.offset}:${start.line}:${start.column}:${end.line}:${end.column}"`;
  };
  const renderChildren = (node: Node): string => (node.children ?? []).map(render).join("");
  const text = (node: Node): string => (node.children ?? []).map((child) => child.value ?? text(child)).join("");
  const blockAttrs = (node: Node): string => ` data-md-block="b-${++block}" data-heading-path="${escape(JSON.stringify(headings))}"${range(node)}`;
  const highlighted = (value: string, language?: string | null): string => {
    if (language && hljs.getLanguage(language)) return hljs.highlight(value, { language, ignoreIllegals: true }).value;
    return language ? escape(value) : hljs.highlightAuto(value).value;
  };
  const sourceLines = (node: Node, className: string, language?: string | null): string => {
    const position = node.position;
    const value = node.value ?? "";
    if (!position) return escape(value);
    const openingNewline = source.indexOf("\n", position.start.offset);
    if (openingNewline < 0) return escape(value);
    let cursor = openingNewline + 1;
    const lines = value.split("\n").map((line) => line.endsWith("\r") ? line.slice(0, -1) : line);
    return lines.map((line, index) => {
      const lineStart = cursor;
      const newline = source.indexOf("\n", lineStart);
      const physicalEnd = newline < 0 ? position.end.offset : newline;
      const lineEnd = physicalEnd > lineStart && source[physicalEnd - 1] === "\r" ? physicalEnd - 1 : physicalEnd;
      const lineNumber = position.start.line + index + 1;
      const lineColumn = index === 0 ? position.start.column : 1;
      cursor = newline < 0 ? position.end.offset : newline + 1;
      return `<span class="${className}" data-md-range="${lineStart}:${lineEnd}:${lineNumber}:${lineColumn}:${lineNumber}:${lineColumn + line.length}"><span class="md-text">${highlighted(line, language)}</span></span>`;
    }).join("");
  };
  const mermaidSource = (node: Node): string => {
    const value = node.value ?? "";
    if (!node.position) return `<pre><code>${escape(value)}</code></pre>`;
    const rendered = sourceLines(node, "mermaid-source-line", "mermaid");
    return `<pre><code>${rendered}</code></pre>`;
  };
  const mediaSource = (node: Node): { url?: string; alt: string; title?: string | null } => {
    if (node.type === "image") return { url: node.url, alt: node.alt ?? "", title: node.title };
    const definition = node.identifier ? definitions.get(node.identifier) : undefined;
    return { url: definition?.url, alt: node.alt ?? "", title: definition?.title };
  };
  const positionAt = (offset: number): Position => {
    const before = source.slice(0, offset);
    const line = before.split("\n").length;
    const lastNewline = before.lastIndexOf("\n");
    return { offset, line, column: offset - lastNewline };
  };
  const mathSourceRange = (node: Node, delimiterLength: number): string => {
    if (!node.position) return "";
    const start = positionAt(node.position.start.offset + delimiterLength);
    const end = positionAt(node.position.end.offset - delimiterLength);
    return ` data-md-range="${start.offset}:${end.offset}:${start.line}:${start.column}:${end.line}:${end.column}"`;
  };
  const mathSourceLines = (node: Node): string => {
    if (!node.position) return `<span class="math-source-line"><span class="md-text">${escape(node.value ?? "")}</span></span>`;
    const value = node.value ?? "";
    const position = node.position;
    const openingNewline = source.indexOf("\n", position.start.offset);
    let cursor = openingNewline < 0 ? position.start.offset + 2 : openingNewline + 1;
    return value.split("\n").map((line, index) => {
      const lineStart = cursor;
      const newline = source.indexOf("\n", lineStart);
      const lineEnd = newline < 0 ? position.end.offset - 2 : newline;
      cursor = newline < 0 ? position.end.offset - 2 : newline + 1;
      const start = positionAt(lineStart);
      const end = positionAt(Math.max(lineStart, lineEnd));
      return `<span class="math-source-line" data-md-range="${start.offset}:${end.offset}:${start.line}:${start.column}:${end.line}:${end.column}"><span class="md-text">${escape(line)}</span></span>`;
    }).join("");
  };
  const imageLocation = (url: string | undefined): { src?: string; error?: string } => {
    if (!url) return { error: "Image reference is missing its definition." };
    if (/^https:/i.test(url)) return { src: url };
    if (/^\/\//.test(url) || /^[a-z][a-z0-9+.-]*:/i.test(url)) return { error: "This image source is blocked. Richie loads only HTTPS and local raster images." };
    if (!options.localImageUrl) return { error: "Local images are unavailable in this view." };
    return { src: options.localImageUrl(url) };
  };
  const renderImage = (image: Node, target: Node = image, href?: string): string => {
    const media = mediaSource(image);
    const location = imageLocation(media.url);
    const quote = target.position ? source.slice(target.position.start.offset, target.position.end.offset) : "";
    const fallback = `<span class="media-fallback"${location.src ? " hidden" : ""}><strong>${escape(location.error ?? "Image could not load.")}</strong><code>${escape(quote)}</code></span>`;
    const picture = location.src ? `<img src="${escape(location.src)}" alt="${escape(media.alt)}"${media.title ? ` title="${escape(media.title)}"` : ""} loading="lazy" decoding="async" referrerpolicy="no-referrer">${fallback}` : fallback;
    const attributes = ` class="media-target" data-md-media data-md-media-source="${escape(quote)}" data-media-state="${location.src ? "loading" : "failed"}"${range(target)}`;
    if (href) return `<a${attributes} href="${escape(href)}" target="_blank" rel="noreferrer">${picture}</a>`;
    return `<span${attributes}>${picture}</span>`;
  };
  const renderText = (node: Node): string => {
    const value = node.value ?? "";
    if (!node.position) return `<span class="md-text">${escape(value)}</span>`;
    const pattern = /!\[([^\]\n]*)\]\[([^\]\n]+)\]/g;
    let cursor = 0;
    let output = "";
    for (const match of value.matchAll(pattern)) {
      const index = match.index;
      const start = node.position.start.offset + index;
      if (source.slice(start, start + 2) !== "![") continue;
      if (index > cursor) {
        const textNode: Node = { type: "text", value: value.slice(cursor, index), position: { start: positionAt(node.position.start.offset + cursor), end: positionAt(start) } };
        output += `<span class="md-text-range"${range(textNode)}><span class="md-text">${escape(textNode.value ?? "")}</span></span>`;
      }
      const end = start + match[0].length;
      output += renderImage({ type: "imageReference", alt: match[1], identifier: match[2].trim().toLowerCase().replace(/\s+/g, " "), position: { start: positionAt(start), end: positionAt(end) } });
      cursor = index + match[0].length;
    }
    if (!output) return `<span class="md-text-range"${range(node)}><span class="md-text">${escape(value)}</span></span>`;
    if (cursor < value.length) {
      const textNode: Node = { type: "text", value: value.slice(cursor), position: { start: positionAt(node.position.start.offset + cursor), end: node.position.end } };
      output += `<span class="md-text-range"${range(textNode)}><span class="md-text">${escape(textNode.value ?? "")}</span></span>`;
    }
    return output;
  };
  const render = (node: Node): string => {
    switch (node.type) {
      case "root": return renderChildren(node);
      case "text": return renderText(node);
      case "paragraph": return `<p${blockAttrs(node)}>${renderChildren(node)}</p>`;
      case "heading": {
        const label = text(node); headings.splice((node.depth ?? 1) - 1); headings[node.depth! - 1] = label;
        const id = slug(label);
        return `<h${node.depth}${blockAttrs(node)} id="${id}">${renderChildren(node)}</h${node.depth}>`;
      }
      case "emphasis": return `<em${range(node)}>${renderChildren(node)}</em>`;
      case "strong": return `<strong${range(node)}>${renderChildren(node)}</strong>`;
      case "delete": return `<del${range(node)}>${renderChildren(node)}</del>`;
      case "inlineMath": {
        const value = node.value ?? "";
        let rendered: string;
        try { rendered = katex.renderToString(value, { displayMode: false, throwOnError: false, output: "html" }); }
        catch { rendered = `<code>${escape(value)}</code>`; }
        return `<span class="math-target math-inline"${range(node)} data-math-source="${escape(value)}"><span class="math-rendered" aria-hidden="true">${rendered}</span><span class="math-source md-text"${mathSourceRange(node, 1)}>${escape(value)}</span></span>`;
      }
      case "math": {
        const value = node.value ?? "";
        let rendered: string;
        try { rendered = katex.renderToString(value, { displayMode: true, throwOnError: false, output: "html" }); }
        catch { rendered = `<code>${escape(value)}</code>`; }
        return `<div class="math-target math-display"${blockAttrs(node)} data-math-source="${escape(value)}"><div class="math-rendered">${rendered}</div><details class="math-source-panel" open><summary>Math source</summary><pre><code>${mathSourceLines(node)}</code></pre></details></div>`;
      }
      case "inlineCode": {
        if (!node.position) return `<code>${escape(node.value ?? "")}</code>`;
        const { start, end } = node.position;
        return `<code data-md-range="${start.offset + 1}:${end.offset - 1}:${start.line}:${start.column + 1}:${end.line}:${Math.max(start.column + 1, end.column - 1)}">${escape(node.value ?? "")}</code>`;
      }
      case "link": {
        const children = node.children ?? [];
        if (children.length === 1 && (children[0].type === "image" || children[0].type === "imageReference")) return renderImage(children[0], node, node.url);
        return `<a${range(node)} href="${escape(node.url ?? "#")}" rel="noreferrer">${renderChildren(node)}</a>`;
      }
      case "image":
      case "imageReference": return renderImage(node);
      case "definition": return "";
      case "break": return "<br>";
      case "thematicBreak": return "<hr>";
      case "blockquote": return `<blockquote${blockAttrs(node)}>${renderChildren(node)}</blockquote>`;
      case "list": return `<${node.ordered ? "ol" : "ul"}${blockAttrs(node)}>${renderChildren(node)}</${node.ordered ? "ol" : "ul"}>`;
      case "listItem": return `<li${blockAttrs(node)}>${node.checked === true ? "<input type=\"checkbox\" checked disabled> " : node.checked === false ? "<input type=\"checkbox\" disabled> " : ""}${renderChildren(node)}</li>`;
      case "code": {
        if (node.lang !== "mermaid") {
          const attrs = blockAttrs(node);
          return `<pre${attrs}><code class="language-${escape(node.lang ?? "")}">${sourceLines(node, "code-source-line", node.lang)}</code></pre>`;
        }
        const attrs = blockAttrs(node);
        return `<div class="mermaid"${attrs} data-mermaid="${escape(node.value ?? "")}"><pre>${escape(node.value ?? "")}</pre></div><details class="mermaid-source"${attrs} data-md-mermaid-source><summary>Mermaid source</summary>${mermaidSource(node)}</details>`;
      }
      case "table": return `<table${blockAttrs(node)}><tbody>${renderChildren(node)}</tbody></table>`;
      case "tableRow": return `<tr${blockAttrs(node)}>${renderChildren(node)}</tr>`;
      case "tableCell": return `<td${blockAttrs(node)}>${renderChildren(node)}</td>`;
      default: return renderChildren(node);
    }
  };
  return render(root);
}
