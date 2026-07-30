import type {
  ExtensionAPI,
  ExtensionCommandContext,
} from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type, type Static } from "typebox";

const API_KEY_ENV = "JINA_API_KEY";
const MAX_OUTPUT = 50_000;
const REQUEST_TIMEOUT_MS = 120_000;
const MAX_ERROR_BODY = 500;
const READER_ENDPOINT = "https://r.jina.ai/";
const SEARCH_ENDPOINT = "https://s.jina.ai/";
const DEEPSEARCH_ENDPOINT = "https://deepsearch.jina.ai/v1/chat/completions";

export type JinaOperation = "read" | "search" | "deepsearch";

export type JinaResult = {
  operation: JinaOperation;
  input: string;
  content: string;
  sources: string[];
  truncated: boolean;
  contentLength: number;
  returnedLength: number;
};

type JinaReadInput = Static<typeof JinaReadSchema>;
type JinaSearchInput = Static<typeof JinaSearchSchema>;
type JinaDeepSearchInput = Static<typeof JinaDeepSearchSchema>;

const JinaReadSchema = Type.Object({
  url: Type.String({ minLength: 1, description: "The exact URL to read." }),
});
const JinaSearchSchema = Type.Object({
  query: Type.String({ minLength: 1, description: "The web search query." }),
});
const JinaDeepSearchSchema = Type.Object({
  prompt: Type.String({ minLength: 1, description: "The research question or prompt." }),
});

function apiKey(): string {
  const key = process.env[API_KEY_ENV]?.trim();
  if (!key) throw new Error(`${API_KEY_ENV} is not set`);
  return key;
}

function validateInput(value: string, label: string): string {
  const trimmed = value.trim();
  if (!trimmed) throw new Error(`${label} is required. No request was made.`);
  return trimmed;
}

function sanitizeErrorBody(body: string): string {
  const key = process.env[API_KEY_ENV];
  const sanitized = key ? body.replaceAll(key, "[REDACTED]") : body;
  return sanitized.replace(/\s+/g, " ").trim().slice(0, MAX_ERROR_BODY);
}

function boundedContent(content: string): Pick<JinaResult, "content" | "truncated" | "contentLength" | "returnedLength"> {
  const contentLength = content.length;
  const bounded = content.slice(0, MAX_OUTPUT);
  return {
    content: bounded,
    truncated: contentLength > bounded.length,
    contentLength,
    returnedLength: bounded.length,
  };
}

function extractSources(content: string, inputSource?: string): string[] {
  const urls = new Set<string>();
  if (inputSource) urls.add(inputSource);
  const markdownLinks = /\]\((https?:\/\/[^\s)]+)\)/g;
  const bareUrls = /https?:\/\/[^\s)\]>]+/g;
  for (const match of content.matchAll(markdownLinks)) urls.add(match[1]);
  for (const match of content.matchAll(bareUrls)) urls.add(match[0].replace(/[.,;:]$/, ""));
  return [...urls].slice(0, 100);
}

function composeSignal(signal: AbortSignal | undefined): { signal: AbortSignal; dispose: () => void } {
  const controller = new AbortController();
  const abort = () => controller.abort(signal?.reason);
  if (signal?.aborted) abort();
  else signal?.addEventListener("abort", abort, { once: true });
  const timer = setTimeout(() => controller.abort(new Error("Request timed out")), REQUEST_TIMEOUT_MS);
  return {
    signal: controller.signal,
    dispose: () => {
      clearTimeout(timer);
      signal?.removeEventListener("abort", abort);
    },
  };
}

async function request(
  operation: string,
  input: RequestInfo | URL,
  init: RequestInit,
  signal?: AbortSignal,
): Promise<string> {
  const composed = composeSignal(signal);
  try {
    const response = await fetch(input, { ...init, signal: composed.signal });
    const body = await response.text();
    if (!response.ok) {
      const detail = sanitizeErrorBody(body);
      throw new Error(`${operation} failed (${response.status})${detail ? `: ${detail}` : ""}`);
    }
    return body;
  } catch (error) {
    if (composed.signal.aborted && !signal?.aborted) {
      throw new Error(`${operation} timed out after ${REQUEST_TIMEOUT_MS / 1000} seconds`);
    }
    if (signal?.aborted) throw new Error(`${operation} was cancelled`);
    throw error;
  } finally {
    composed.dispose();
  }
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
      chunks.push(value);
    }
  }
  return chunks.length > 0 ? chunks.join("") : body;
}

function makeResult(operation: JinaOperation, input: string, content: string, inputSource?: string): JinaResult {
  const bounded = boundedContent(content);
  return {
    operation,
    input,
    ...bounded,
    sources: extractSources(content, inputSource),
  };
}

async function readUrl(url: string, signal?: AbortSignal): Promise<JinaResult> {
  const input = validateInput(url, "URL");
  const body = await request("Jina Reader", `${READER_ENDPOINT}${input}`, {
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
  }, signal);
  return makeResult("read", input, body, input);
}

async function search(query: string, signal?: AbortSignal): Promise<JinaResult> {
  const input = validateInput(query, "Search query");
  const url = new URL(SEARCH_ENDPOINT);
  url.searchParams.set("q", input);
  const body = await request("Jina Search", url, {
    headers: { Authorization: `Bearer ${apiKey()}`, "X-Return-Format": "markdown" },
  }, signal);
  return makeResult("search", input, body);
}

async function deepSearch(prompt: string, signal?: AbortSignal): Promise<JinaResult> {
  const input = validateInput(prompt, "Research prompt");
  const body = await request("Jina DeepSearch", DEEPSEARCH_ENDPOINT, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${apiKey()}` },
    body: JSON.stringify({
      model: "jina-deepsearch-v1",
      messages: [{ role: "user", content: input }],
      stream: true,
      reasoning_effort: "medium",
    }),
  }, signal);
  return makeResult("deepsearch", input, parseDeepSearchSse(body));
}

function help(operation: JinaOperation): string {
  switch (operation) {
    case "read": return "Usage: /jina-read <url>\nReads a specific URL with Jina Reader.";
    case "search": return "Usage: /jina-search <query>\nSearches the web with Jina Search.";
    case "deepsearch": return "Usage: /jina-deepsearch <prompt>\nResearches a question with Jina DeepSearch.";
  }
}

function formatResult(result: JinaResult): string {
  const sources = result.sources.length > 0 ? `\n\nSources:\n${result.sources.map((url) => `- ${url}`).join("\n")}` : "";
  const truncation = result.truncated
    ? `\n\n[Output truncated: returned ${result.returnedLength} of ${result.contentLength} characters]`
    : "";
  return `${result.content}${sources}${truncation}`;
}

function publish(pi: ExtensionAPI, ctx: ExtensionCommandContext, result: JinaResult): void {
  pi.sendMessage({
    customType: "jina-result",
    content: formatResult(result),
    display: true,
    details: result,
  });
  if (ctx.hasUI) ctx.ui.notify(`jina ${result.operation} completed`, "info");
}

async function runCommand(
  pi: ExtensionAPI,
  ctx: ExtensionCommandContext,
  operation: JinaOperation,
  input: string,
  requestOperation: () => Promise<JinaResult>,
): Promise<void> {
  if (!input.trim()) {
    if (ctx.hasUI) ctx.ui.notify(help(operation), "info");
    return;
  }
  try {
    publish(pi, ctx, await requestOperation());
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (ctx.hasUI) ctx.ui.notify(message, "error");
  }
}

function toolResult(result: JinaResult) {
  return { content: [{ type: "text" as const, text: JSON.stringify(result) }], details: result };
}

export default function (pi: ExtensionAPI): void {
  pi.registerMessageRenderer("jina-result", (message, options, theme) => {
    const details = message.details as { operation?: string } | undefined;
    const prefix = theme.fg("accent", `[jina ${details?.operation ?? "result"}]`);
    const body = typeof message.content === "string" ? message.content : JSON.stringify(message.content);
    return new Text(`${prefix}\n${body}`, options.outputPad, 0);
  });

  pi.registerCommand("jina-read", {
    description: "Read an explicitly supplied URL with Jina Reader",
    handler: async (args, ctx) => runCommand(pi, ctx, "read", args, () => readUrl(args)),
  });
  pi.registerCommand("jina-search", {
    description: "Search the web with explicitly supplied query terms",
    handler: async (args, ctx) => runCommand(pi, ctx, "search", args, () => search(args)),
  });
  pi.registerCommand("jina-deepsearch", {
    description: "Research an explicitly supplied question with Jina DeepSearch",
    handler: async (args, ctx) => runCommand(pi, ctx, "deepsearch", args, () => deepSearch(args)),
  });

  pi.registerTool({
    name: "jina_read",
    label: "Jina Read",
    description: "Read a known URL as Markdown. Requires an explicit URL; do not call without one.",
    promptSnippet: "Read a known URL with Jina Reader",
    promptGuidelines: ["Use jina_read when the user gives you a specific URL whose contents need to be read."],
    parameters: JinaReadSchema,
    async execute(_toolCallId, params: JinaReadInput, signal) {
      return toolResult(await readUrl(params.url, signal));
    },
  });
  pi.registerTool({
    name: "jina_search",
    label: "Jina Search",
    description: "Search the web for explicit query terms. Requires a non-empty query; do not invent one.",
    promptSnippet: "Search the web with Jina Search",
    promptGuidelines: ["Use jina_search for current web results when you have explicit search terms from the user's request."],
    parameters: JinaSearchSchema,
    async execute(_toolCallId, params: JinaSearchInput, signal) {
      return toolResult(await search(params.query, signal));
    },
  });
  pi.registerTool({
    name: "jina_deepsearch",
    label: "Jina DeepSearch",
    description: "Research an explicit question with Jina DeepSearch. Requires a non-empty prompt; do not invent one.",
    promptSnippet: "Research a question with Jina DeepSearch",
    promptGuidelines: ["Use jina_deepsearch for multi-step research when the user has supplied a specific question or research goal."],
    parameters: JinaDeepSearchSchema,
    async execute(_toolCallId, params: JinaDeepSearchInput, signal) {
      return toolResult(await deepSearch(params.prompt, signal));
    },
  });
}
