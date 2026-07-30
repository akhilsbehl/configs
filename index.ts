import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

const API_KEY_ENV = "JINA_API_KEY";
const MAX_OUTPUT = 50_000;

function apiKey(): string {
  const key = process.env[API_KEY_ENV];
  if (!key) {
    throw new Error(`${API_KEY_ENV} is not set`);
  }
  return key;
}

function trimOutput(text: string): string {
  if (text.length <= MAX_OUTPUT) return text;
  return `${text.slice(0, MAX_OUTPUT)}\n\n[Output truncated at ${MAX_OUTPUT} characters]`;
}

function publish(pi: ExtensionAPI, ctx: ExtensionCommandContext, command: string, text: string): void {
  const content = trimOutput(text);
  pi.sendMessage({
    customType: "jina-result",
    content,
    display: true,
    details: { command },
  });
  if (ctx.hasUI) ctx.ui.notify(`${command} completed`, "info");
}

async function readUrl(url: string): Promise<string> {
  const response = await fetch(`https://r.jina.ai/${url}`, {
    headers: {
      Authorization: `Bearer ${apiKey()}`,
      "X-Engine": "browser",
      "X-Respond-Timing": "mutation-idle",
      "X-Retain-Images": "none",
      "X-Retain-Links": "gpt-oss",
      "X-Return-Format": "markdown",
      "X-Robots-Txt": "JinaReader",
      "X-Token-Budget": "75000",
      "X-With-Iframe": "true",
      "X-With-Images-Summary": "true",
    },
  });
  if (!response.ok) throw new Error(`Jina Reader failed (${response.status}): ${await response.text()}`);
  return response.text();
}

async function search(query: string): Promise<string> {
  const response = await fetch(`https://s.jina.ai/?q=${encodeURIComponent(query)}`, {
    headers: {
      Authorization: `Bearer ${apiKey()}`,
      "X-Return-Format": "markdown",
    },
  });
  if (!response.ok) throw new Error(`Jina Search failed (${response.status}): ${await response.text()}`);
  return response.text();
}

function parseDeepSearchSse(body: string): string {
  const chunks: string[] = [];
  for (const line of body.split(/\r?\n/)) {
    if (!line.startsWith("data:")) continue;
    const value = line.slice(5).trim();
    if (!value || value === "[DONE]") continue;
    try {
      const json = JSON.parse(value) as { choices?: Array<{ delta?: { content?: string } }> };
      const content = json.choices?.[0]?.delta?.content;
      if (content) chunks.push(content);
    } catch {
      // Keep non-JSON data lines. This also supports a non-streaming response.
      chunks.push(value);
    }
  }
  return chunks.length > 0 ? chunks.join("") : body;
}

async function deepSearch(prompt: string): Promise<string> {
  const response = await fetch("https://deepsearch.jina.ai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey()}`,
    },
    body: JSON.stringify({
      model: "jina-deepsearch-v1",
      messages: [{ role: "user", content: prompt }],
      stream: true,
      reasoning_effort: "medium",
    }),
  });
  if (!response.ok) throw new Error(`Jina DeepSearch failed (${response.status}): ${await response.text()}`);
  return parseDeepSearchSse(await response.text());
}

async function runCommand(
  pi: ExtensionAPI,
  ctx: ExtensionCommandContext,
  command: string,
  operation: () => Promise<string>,
): Promise<void> {
  try {
    publish(pi, ctx, command, await operation());
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (ctx.hasUI) ctx.ui.notify(message, "error");
    else pi.sendMessage({ customType: "jina-result", content: `Error: ${message}`, display: true });
  }
}

export default function (pi: ExtensionAPI): void {
  pi.registerMessageRenderer("jina-result", (message, options, theme) => {
    const details = message.details as { command?: string } | undefined;
    const prefix = theme.fg("accent", `[${details?.command ?? "jina"}]`);
    const body = typeof message.content === "string" ? message.content : JSON.stringify(message.content);
    return new Text(`${prefix}\n${body}`, options.outputPad, 0);
  });

  pi.registerCommand("jina-read", {
    description: "Read a URL as Markdown with Jina Reader",
    handler: async (args, ctx) => runCommand(pi, ctx, "jina-read", () => readUrl(args.trim() || "https://www.example.com")),
  });

  pi.registerCommand("jina-search", {
    description: "Search the web with Jina Search",
    handler: async (args, ctx) => runCommand(pi, ctx, "jina-search", () => search(args.trim() || "Jina AI")),
  });

  pi.registerCommand("jina-deepsearch", {
    description: "Research a question with Jina DeepSearch",
    handler: async (args, ctx) => runCommand(
      pi,
      ctx,
      "jina-deepsearch",
      () => deepSearch(args.trim() || "What's the latest blog post from Jina AI?"),
    ),
  });
}
