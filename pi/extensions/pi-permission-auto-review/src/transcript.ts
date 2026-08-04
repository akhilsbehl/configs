import type { SessionEntry } from '@earendil-works/pi-coding-agent'

const MAX_RECENT_ENTRIES = 40
const MAX_MESSAGE_TRANSCRIPT_TOKENS = 10_000
const MAX_TOOL_TRANSCRIPT_TOKENS = 10_000
const MAX_MESSAGE_ENTRY_TOKENS = 2_000
const MAX_TOOL_ENTRY_TOKENS = 1_000

type TranscriptKind = 'user' | 'assistant' | 'tool'

export interface TranscriptEntry {
  index: number
  kind: TranscriptKind
  label: string
  text: string
}

export interface RenderedTranscript {
  entries: string[]
  omittedCount: number
}

interface ContentBlock {
  type?: unknown
  text?: unknown
  thinking?: unknown
  name?: unknown
  toolName?: unknown
  arguments?: unknown
}

interface MessageLike {
  role?: unknown
  content?: unknown
  command?: unknown
  output?: unknown
  summary?: unknown
  toolName?: unknown
  isError?: unknown
}

function approximateTokens(text: string): number {
  return Math.ceil(text.length / 4)
}

export function truncateToApproximateTokens(text: string, maxTokens: number): string {
  const maxCharacters = maxTokens * 4
  if (text.length <= maxCharacters) {
    return text
  }
  const tag = '\n...[truncated]...\n'
  const available = Math.max(0, maxCharacters - tag.length)
  const headLength = Math.floor(available * 0.7)
  const tailLength = available - headLength
  return `${text.slice(0, headLength)}${tag}${text.slice(-tailLength)}`
}

function serializeUnknown(value: unknown): string {
  if (typeof value === 'string') {
    return value
  }
  try {
    return JSON.stringify(value)
  } catch {
    return String(value)
  }
}

function textFromContent(content: unknown): string {
  if (typeof content === 'string') {
    return content
  }
  if (!Array.isArray(content)) {
    return serializeUnknown(content)
  }
  return content
    .map(rawBlock => {
      const block = rawBlock as ContentBlock
      if (block.type === 'text' && typeof block.text === 'string') {
        return block.text
      }
      if (block.type === 'image') {
        return '[image omitted]'
      }
      return ''
    })
    .filter(Boolean)
    .join('\n')
}

function assistantEntries(message: MessageLike, index: number): TranscriptEntry[] {
  const content = Array.isArray(message.content) ? message.content : []
  const text = textFromContent(message.content)
  const entries: TranscriptEntry[] = []
  if (text) {
    entries.push({ index, kind: 'assistant', label: 'assistant', text })
  }
  for (const rawBlock of content) {
    const block = rawBlock as ContentBlock
    if (block.type !== 'toolCall') {
      continue
    }
    const name =
      typeof block.name === 'string' ? block.name : typeof block.toolName === 'string' ? block.toolName : 'unknown'
    entries.push({
      index,
      kind: 'tool',
      label: `tool:${name}`,
      text: serializeUnknown(block.arguments),
    })
  }
  return entries
}

function entriesFromMessage(message: MessageLike, index: number): TranscriptEntry[] {
  switch (message.role) {
    case 'user': {
      const text = textFromContent(message.content)
      return text ? [{ index, kind: 'user', label: 'user', text }] : []
    }
    case 'assistant':
      return assistantEntries(message, index)
    case 'toolResult': {
      const name = typeof message.toolName === 'string' ? message.toolName : 'unknown'
      const suffix = message.isError === true ? ' (error)' : ''
      const text = textFromContent(message.content)
      return text ? [{ index, kind: 'tool', label: `tool:${name}${suffix}`, text }] : []
    }
    case 'bashExecution': {
      const command = serializeUnknown(message.command)
      const output = serializeUnknown(message.output)
      return [
        {
          index,
          kind: 'tool',
          label: 'tool:user-bash',
          text: `${command}\n${output}`,
        },
      ]
    }
    case 'branchSummary':
    case 'compactionSummary': {
      const text = serializeUnknown(message.summary)
      return text ? [{ index, kind: 'assistant', label: String(message.role), text }] : []
    }
    case 'custom': {
      const text = textFromContent(message.content)
      return text ? [{ index, kind: 'assistant', label: 'custom', text }] : []
    }
    default:
      return []
  }
}

export function collectTranscriptEntries(sessionEntries: SessionEntry[]): TranscriptEntry[] {
  return sessionEntries.flatMap((entry, index) => {
    if (entry.type === 'message') {
      return entriesFromMessage(entry.message as MessageLike, index)
    }
    if (entry.type === 'compaction' || entry.type === 'branch_summary') {
      return [
        {
          index,
          kind: 'assistant' as const,
          label: entry.type,
          text: entry.summary,
        },
      ]
    }
    if (entry.type === 'custom_message') {
      const text = textFromContent(entry.content)
      return text
        ? [
            {
              index,
              kind: 'assistant' as const,
              label: 'custom',
              text,
            },
          ]
        : []
    }
    return []
  })
}

function pretruncate(entry: TranscriptEntry): TranscriptEntry {
  const maxTokens = entry.kind === 'tool' ? MAX_TOOL_ENTRY_TOKENS : MAX_MESSAGE_ENTRY_TOKENS
  return {
    ...entry,
    text: truncateToApproximateTokens(entry.text, maxTokens),
  }
}

function addWithinBudget(selected: Set<TranscriptEntry>, entries: TranscriptEntry[], budget: number): number {
  let used = 0
  for (const entry of entries) {
    const tokens = approximateTokens(entry.text)
    if (used + tokens > budget) {
      continue
    }
    selected.add(entry)
    used += tokens
  }
  return used
}

export function renderTranscript(sessionEntries: SessionEntry[]): RenderedTranscript {
  const allEntries = collectTranscriptEntries(sessionEntries).map(pretruncate)
  const selected = new Set<TranscriptEntry>()
  const messages = allEntries.filter(entry => entry.kind !== 'tool')
  const users = messages.filter(entry => entry.kind === 'user')

  let messageTokens = 0
  if (users.length > 0) {
    const first = users[0]
    const latest = users.at(-1)
    if (first !== undefined) {
      selected.add(first)
      messageTokens += approximateTokens(first.text)
    }
    if (latest !== undefined && latest !== first) {
      selected.add(latest)
      messageTokens += approximateTokens(latest.text)
    }
  }

  const remainingUsers = users.filter(entry => !selected.has(entry)).toReversed()
  messageTokens += addWithinBudget(selected, remainingUsers, MAX_MESSAGE_TRANSCRIPT_TOKENS - messageTokens)

  const assistants = messages.filter(entry => entry.kind === 'assistant').toReversed()
  addWithinBudget(selected, assistants, MAX_MESSAGE_TRANSCRIPT_TOKENS - messageTokens)

  const tools = allEntries.filter(entry => entry.kind === 'tool').toReversed()
  addWithinBudget(selected, tools, MAX_TOOL_TRANSCRIPT_TOKENS)

  let retained = [...selected].sort((left, right) => left.index - right.index)
  if (retained.length > MAX_RECENT_ENTRIES) {
    const firstUser = retained.find(entry => entry.kind === 'user')
    retained = retained.slice(-MAX_RECENT_ENTRIES)
    if (firstUser !== undefined && !retained.includes(firstUser)) {
      retained = [firstUser, ...retained.slice(-(MAX_RECENT_ENTRIES - 1))]
    }
  }

  return {
    entries: retained.map(entry =>
      JSON.stringify({
        source: entry.kind,
        label: entry.label,
        content: entry.text,
      }),
    ),
    omittedCount: allEntries.length - retained.length,
  }
}
