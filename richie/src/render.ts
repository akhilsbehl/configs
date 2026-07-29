import { unified } from "unified";
import hljs from "highlight.js";
import remarkGfm from "remark-gfm";
import remarkParse from "remark-parse";

type Node = { type: string; value?: string; depth?: number; url?: string; lang?: string | null; checked?: boolean | null; ordered?: boolean | null; align?: Array<string | null>; children?: Node[]; position?: { start: Position; end: Position } };
type Position = { line: number; column: number; offset: number };

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
  return unified().use(remarkParse).use(remarkGfm).parse(source) as unknown as Node;
}

export function renderReviewHtml(source: string): string {
  const root = parseMarkdown(source);
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
  const render = (node: Node): string => {
    switch (node.type) {
      case "root": return renderChildren(node);
      case "text": return `<span class="md-text-range"${range(node)}><span class="md-text">${escape(node.value ?? "")}</span></span>`;
      case "paragraph": return `<p${blockAttrs(node)}>${renderChildren(node)}</p>`;
      case "heading": {
        const label = text(node); headings.splice((node.depth ?? 1) - 1); headings[node.depth! - 1] = label;
        const id = slug(label);
        return `<h${node.depth}${blockAttrs(node)} id="${id}">${renderChildren(node)}</h${node.depth}>`;
      }
      case "emphasis": return `<em${range(node)}>${renderChildren(node)}</em>`;
      case "strong": return `<strong${range(node)}>${renderChildren(node)}</strong>`;
      case "delete": return `<del${range(node)}>${renderChildren(node)}</del>`;
      case "inlineCode": {
        if (!node.position) return `<code>${escape(node.value ?? "")}</code>`;
        const { start, end } = node.position;
        return `<code data-md-range="${start.offset + 1}:${end.offset - 1}:${start.line}:${start.column + 1}:${end.line}:${Math.max(start.column + 1, end.column - 1)}">${escape(node.value ?? "")}</code>`;
      }
      case "link": return `<a${range(node)} href="${escape(node.url ?? "#")}" rel="noreferrer">${renderChildren(node)}</a>`;
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
