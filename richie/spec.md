# Markdown Visual Review Layer: Solution Specification

## 1. Decision

Build a small, local Markdown review tool. It renders a canonical Markdown draft as HTML, lets a reviewer express editorial changes visually, and stores those changes as structured review operations. An agent applies the operations back to Markdown.

Markdown remains the source of truth. Git remains the provenance and change-history system. Generated HTML is disposable. The tool does not edit HTML or round-trip HTML back to Markdown.

## 2. Working context, review problem, and preferred workflow

### 2.1 Current context

The reviewer uses Markdown primarily for document reviews. Markdown is the versioned, durable document source and must remain so.

The work is primarily professional knowledge work: research, plans, reports, technical and product documents, and other drafts that benefit from agent-assisted iteration. The default audience is often a senior business or technical professional. Review needs to preserve precise reasoning, factual accuracy, and document structure, not merely improve appearance.

### 2.2 Review mix and frequency

The review mix contains both semantic/editorial work and visual/spatial judgement, but it leans heavily toward semantic/editorial work. No numeric frequency has been specified and this specification must not invent one.

| Review mode | Relative frequency | Examples |
|---|---:|---|
| Semantic and editorial | Dominant | Argument, factual accuracy, wording, evidence, logical structure, narrative flow, and recommendation clarity. |
| Visual and spatial | Material but secondary | Executive scanability, hierarchy, long tables, Mermaid diagrams, and page composition. |
| Presentation-specific | Occasional and separate | Slide narrative and slide layout. This belongs in a deck workflow, not the Markdown review tool. |

The tool must therefore be optional. It should improve review ergonomics where visual rendering helps, without imposing an HTML review loop on every Markdown draft.

### 2.3 Typical editorial routine

A typical review is not a wholesale rewrite. It is a sequence of local and higher-level editorial actions:

1. Read the rendered document to assess hierarchy, scanability, and narrative flow.
2. Strike out a few words, a line, or an entire content chunk that should be removed.
3. Reword a phrase, an entire line, or a larger passage when the intended wording is clear.
4. Add an editorial comment beside a word, phrase, paragraph, section, table, or Mermaid source line when the required change needs agent judgement.
5. Add a document-level note for cross-cutting instructions, such as a missing recommendation or a structural issue.
6. Have the agent apply feedback to the Markdown source and produce the next versioned draft.

### 2.4 Preferred workflow

The preferred workflow has five non-negotiable properties:

- **Markdown source provenance:** the versioned `.md` file is canonical and must remain readable, portable, and Git-diffable.
- **Visual review without source conversion:** rendered HTML improves scanning, but is a disposable projection. There is no HTML-to-Markdown round trip.
- **Structured feedback:** strikethroughs, replacements, and comments become explicit review operations rather than unstructured browser annotations.
- **Agent-applied changes:** the agent updates Markdown and explains what changed. The reviewer does not need to hand-edit Markdown merely to express ordinary editorial feedback.
- **Git-visible review trail:** feedback remains visible in a committed sidecar until it has been resolved, rejected with rationale, or marked as needing reviewer input.

## 3. Problem

Markdown provides the required provenance, but a rendered review surface is better suited when a reviewer wants to:

- Strike out a word, sentence, paragraph, or section.
- Propose replacement wording for a phrase, line, or larger passage.
- Put an editorial comment next to selected text.
- Comment on a paragraph, section, table, or the document as a whole.
- Scan the rendered hierarchy, tables, and diagrams before giving feedback.

A visual review surface should make these editorial actions fast without replacing Markdown provenance.

## 4. Goals

1. Keep a versioned `.md` file as the sole canonical document.
2. Make rendered documents easier to scan and review visually.
3. Capture editorial review feedback as exact, machine-readable operations.
4. Preserve enough source identity for an agent to apply feedback safely.
5. Retain review provenance in Git through a committed feedback sidecar.
6. Support a single local reviewer and a local agent workflow first.
7. Require little operational machinery: no cloud service, account, background daemon, chat system, or live polling in the MVP.

## 5. Non-goals

- Rich-text authoring or direct WYSIWYG editing of the canonical document.
- HTML-to-Markdown conversion.
- Multi-user simultaneous editing or conflict resolution.
- General-purpose HTML annotation.
- Slide creation. Marp is not in scope. It is appropriate when the deliverable is a deck, not when the primary artifact is a prose document.
- Layout-quality auditing, hosted sharing, export bundling, or editable Mermaid whiteboards.
- Replacing the canonical Markdown file or its Git history.

## 6. Operating model

```text
<draft>-v03.md
       |
       | render with source positions
       v
<draft>-v03.review.html
       |
       | visual review: delete, replace, comment
       v
<draft>-v03.review.json
       |
       | agent reads, validates, applies operations
       v
<draft>-v04.md
```

### Rules

- The Markdown draft is edited only by the author or agent.
- Review HTML is generated and never committed by default.
- The JSON sidecar is committed while it contains open review feedback.
- The agent updates Markdown, not generated HTML.
- The agent records whether each operation was applied, rejected, or needs reviewer input.
- Every review session is tied to a content hash of the exact Markdown version reviewed.

## 7. Review operations

The review UI offers three primary operations plus scope selection and review lifecycle controls.

| Reviewer intent | Operation | Required data |
|---|---|---|
| Strike out content | `delete` | Source range, quoted source text, context anchors |
| Reword content | `replace` | Source range, quoted source text, proposed replacement, context anchors |
| Explain a concern or request | `comment` | Selected range or scope anchor, comment text, context anchors |
| Comment on a paragraph or table row | `comment` | Block anchor and optional range |
| Comment on a section | `comment` | Heading anchor and heading path |
| Comment on the whole document | `comment` | `scope: "document"` and placement `start` |

The UI may render pending deletions with strikethrough and proposed replacements in a tracked-change style. This is a visual representation of a stored operation, not a mutation of the Markdown file.

For Mermaid fences, the review surface displays both the rendered SVG and the original Mermaid source. The SVG is visual context only. Selection-based operations target source lines or source text, preserving source-aware ranges for agent review. SVG nodes, edges, and labels are not independent review targets. Exported feedback for Mermaid or other fenced-code ranges sits after the closing fence so the source remains valid.

## 8. Source identity and mapping

### 8.1 Requirement

Line mapping alone is insufficient. A reviewer needs to select a few words inside a sentence. The system must map rendered selections to **character-precise Markdown source ranges**, while retaining block and section context.

Each annotation stores:

- A half-open or clearly defined start and end position: line and column.
- The exact source quote at review time.
- A short prefix and suffix around the quote.
- The nearest block ID.
- The heading path from document root to that block.
- The Markdown content SHA-256 at review creation.

The redundant anchors make feedback recoverable when line numbers change after earlier operations.

### 8.2 Renderer output

The Markdown renderer must retain CommonMark or parser source positions and produce stable metadata in the review HTML.

Block-level example:

```html
<p data-md-block="b-12" data-md-range="42:1-46:18">
  ...
</p>
```

Inline-level example:

```html
<span data-md-range="42:18-42:53">
  a vague and largely unsubstantiated claim
</span>
```

The renderer must also instrument inline text inside emphasis, strong text, links, code spans, and list items. A browser selection may cross several spans. The selection mapper derives its start from the first selected text node and its end from the last selected text node.

Source position metadata belongs only in review HTML. It must not appear in the canonical Markdown.

### 8.3 Stable block and heading identity

- Blocks receive deterministic IDs based on document order plus their source range.
- Headings receive a normalized slug and an ordinal where duplicates exist, for example `risk-2`.
- Each operation stores a `heading_path`, such as `["Executive summary", "Risks"]`.
- A section-level comment targets a heading ID and its initial source range.
- A document-level comment has no source range and explicitly uses `scope: "document"`.

## 9. Feedback sidecar

The feedback sidecar sits beside the source draft:

```text
strategy-v03.md
strategy-v03.review.json
strategy-v03.review.html     # generated, ignored by Git
```

### 9.1 JSON schema, illustrative

```json
{
  "schema_version": 1,
  "source": "strategy-v03.md",
  "source_sha256": "a0b1...",
  "created_at": "2026-03-15T12:00:00Z",
  "reviewer": "ASB",
  "operations": [
    {
      "id": "rvw_001",
      "kind": "replace",
      "status": "open",
      "range": {
        "start": { "line": 42, "column": 18 },
        "end": { "line": 42, "column": 53 }
      },
      "quote": "a vague and largely unsubstantiated claim",
      "prefix": "This is ",
      "suffix": ". It should",
      "block_id": "b-12",
      "heading_path": ["Executive summary"],
      "replacement": "a claim unsupported by the current evidence",
      "created_at": "2026-03-15T12:04:00Z"
    },
    {
      "id": "rvw_002",
      "kind": "delete",
      "status": "open",
      "range": {
        "start": { "line": 75, "column": 1 },
        "end": { "line": 78, "column": 1 }
      },
      "quote": "The current four-sentence paragraph...",
      "prefix": "",
      "suffix": "## Delivery plan",
      "block_id": "b-21",
      "heading_path": ["Market context"],
      "created_at": "2026-03-15T12:08:00Z"
    },
    {
      "id": "rvw_003",
      "kind": "comment",
      "status": "open",
      "scope": "section",
      "heading_id": "risks",
      "heading_path": ["Risks"],
      "comment": "Separate controllable execution risks from external market risks.",
      "created_at": "2026-03-15T12:12:00Z"
    },
    {
      "id": "rvw_004",
      "kind": "comment",
      "status": "open",
      "scope": "document",
      "placement": "start",
      "comment": "The document needs a clearer recommendation before its supporting detail.",
      "created_at": "2026-03-15T12:15:00Z"
    }
  ]
}
```

### 9.2 Operation statuses

| Status | Meaning |
|---|---|
| `open` | Reviewer feedback has not been handled. |
| `applied` | Agent changed Markdown in response. Store the resulting Git commit and optional target range. |
| `rejected` | Agent did not make the requested change. A mandatory rationale explains why. |
| `needs-review` | The source moved or feedback is ambiguous. The reviewer must decide. |
| `superseded` | A later review operation replaced this one. |

The sidecar must retain historical operations. It should not silently delete resolved feedback.

## 10. Reviewer experience

### 10.1 Review page

The browser page contains:

- A readable rendered Markdown document.
- A restrained review toolbar with `Document level note`, `Abort review`, and `Finish review` actions.
- Source-mapped text affordances with `Comment`, `Replace`, and `Delete` actions for individual text ranges.
- A left navigation sidebar for the document outline and a right review-inventory sidebar listing open operations.
- Clear visual treatment for selected text, pending deletions, and replacements.
- Section controls on headings for section-level comments.
- Document-level controls at the top and bottom.
- A `Finish review` action that asks for confirmation, verifies feedback was saved, avoids exporting when there is no open feedback, closes the review tab after the response, and displays the next agent command when feedback was exported.
- An `Abort review` action that asks for confirmation, discards open feedback without exporting, removes the sidecar, closes the session, and closes the review tab after the response.

The interface should be visually quiet. Its purpose is reading and editorial judgement, not an app-like collaboration environment.

### 10.2 Interaction details

**Text selection**

1. Reviewer selects rendered text.
2. The action menu appears beneath the selection.
3. Reviewer selects Delete, Replace, or Comment.
4. Delete requires confirmation only for large selections.
5. Replace opens a compact field for replacement text.
6. Comment opens a compact note field.
7. The operation is saved immediately to the sidecar and appears in the review panel.

**Block and section comments**

- Hovering a paragraph, list item, table row, or heading reveals a comment affordance.
- Clicking it produces a block or section comment without requiring text selection.
- Table-row support is optional in the MVP if the renderer cannot assign a clean source range for each row.

**Source-mapped text actions**

- Hovering source-mapped text opens a `Comment`, `Replace`, and `Delete` menu beneath that exact range without changing document flow. When a visual selection is active, those actions target the selection instead of the hovered range.
- When a selection spans multiple source ranges, the hovered-range menu applies the action to the active selection.

**Document comments**

- `Document level note` creates an explicitly document-scoped note at the top of the commented copy.
- The note must not be attached to an arbitrary last paragraph.

**Operation editing**

- Reviewers may amend or delete an open operation.
- The tool records `updated_at` and preserves original values where useful.
- Open operations remain visible across a browser refresh.

## 11. Agent workflow

1. Agent writes or updates `draft-v03.md`.
2. Reviewer opens the local review application for that draft.
3. Reviewer performs a visual review, expands Mermaid source when needed, and clicks `Finish review` or `Abort review`.
4. `Finish review` exports the commented copy when open feedback exists and removes the sidecar. `Abort review` discards the sidecar without exporting.
5. Agent reads the commented copy or sidecar, as applicable.
6. Agent validates the source hash and each target.
7. Agent applies feedback to Markdown only.
8. Agent updates each operation status and records rationale where needed.
9. Agent writes the next versioned draft and reports what changed.

The application starts and stops its local review server automatically. There is no command-line interface, agent polling, or long-running server lifecycle in the user workflow.

## 12. Stale feedback and safe application

### 12.1 Initial validation

Before applying any operation, compare the current Markdown SHA-256 with `source_sha256`.

- If equal, source ranges can be used directly after applying changes from bottom to top within the file.
- If different, direct line and column application is unsafe.

### 12.2 Re-anchoring sequence

For an operation against changed source:

1. Search for the exact `quote`.
2. If exactly one occurrence exists, validate its prefix, suffix, block ID, and heading path.
3. If necessary, search within the stored heading path or block range.
4. If exactly one safe match remains, update the operation with a `reanchored_range` and apply it.
5. If no safe match or multiple matches remain, set `status: "needs-review"`.

The agent must never guess between duplicate passages or silently apply a replacement to a merely similar phrase.

### 12.3 Application order

- Apply document and section comments as editorial instructions, not mechanical patches.
- Apply exact text operations from the bottom of the Markdown file upward so earlier coordinates remain valid.
- Revalidate each operation against the current in-memory document before applying it.
- A replacement must match the original quote exactly before mutation unless it was safely re-anchored.

## 13. Technical architecture

### 13.1 Components

| Component | Responsibility |
|---|---|
| Review application | Opens a selected Markdown draft, starts the local review server, and shows review completion state. |
| Renderer | Parse Markdown with source positions and write review HTML with source metadata. |
| Local server | Serve the review page and accept local feedback writes. |
| Browser overlay | Capture selections and block targets, render review operations, and persist them. |
| Sidecar store | Read, validate, atomically write, and update JSON feedback state. |

### 13.2 Local server

The MVP needs a short-lived local HTTP server because browsers cannot reliably write to a local JSON file directly. It should:

- Bind only to loopback.
- Serve a single review session for a declared Markdown path.
- Expose only the minimum routes:
  - `GET /` for review HTML.
  - `GET /api/review` for current state.
  - `POST /api/operations` to create or modify operations.
  - `POST /api/finish` to mark review finished.
- Validate that all writes are for the active source file.
- Shut down when the browser session ends or after a short idle timeout.

There is no need for session persistence across server restarts in the MVP. The sidecar is the persistent state.

### 13.3 Trust model

- The tool serves locally generated HTML from the known Markdown source.
- It does not serve arbitrary user HTML.
- It does not require an iframe sandbox in the MVP.
- It binds to `127.0.0.1` only and rejects unexpected `Host` headers.
- It accepts same-origin JSON writes only.
- It does not make outbound requests.
- It reads and writes only the declared Markdown and sibling sidecar paths.

## 14. Rendering choices

The renderer must be selected based on source-position fidelity, not visual polish alone.

Required capabilities:

- Standard Markdown features used in existing drafts: headings, emphasis, lists, links, blockquotes, code, tables, task lists, and Mermaid fences where relevant.
- Parser position information for block and inline nodes.
- Custom HTML generation that retains source ranges.
- Predictable output across runs.
- A document stylesheet designed for reading and scanability, not a slide layout.

Possible implementation direction:

- Parse Markdown into an AST with source positions.
- Generate review HTML from that AST through a custom renderer or compiler plugin.
- Attach `data-md-range`, block IDs, and heading identity while generating HTML.
- Render Mermaid as a view feature with the SVG and source code displayed together. Mermaid source remains in Markdown and is not directly editable in the review tool, but its lines can be selected for comments, replacements, and deletions.

The source renderer must be tested against the exact Markdown conventions in existing drafts, especially `<<ASB: ...>>` markers, tables, nested lists, links, and code blocks.

## 15. MVP scope

### Include

- One Markdown file per local review session.
- Rendered document with readable document styling.
- Text-range Delete, Replace, and Comment operations.
- Paragraph and heading comments.
- Document-level comments.
- JSON sidecar persistence.
- Source hash validation.
- Manual agent application workflow.
- Tests for source mapping, selection serialization, sidecar writes, stale-source handling, and safe re-anchoring.

### Exclude initially

- Concurrent reviewers.
- Agent long polling, SSE, presence indicators, chat, or agent replies.
- Direct source edits from the browser.
- Arbitrary HTML support.
- Whiteboards and diagram editing.
- Export, hosted sharing, authentication, cloud storage, or account management.
- Automated application of operations without an agent reviewing the target.

## 16. Acceptance criteria

1. A reviewer can select one word inside a paragraph and create a replacement suggestion with an exact Markdown range.
2. A reviewer can strike out a selected sentence and see it rendered as a pending deletion.
3. A reviewer can comment on a paragraph, a section, and the whole document.
4. Refreshing the page preserves all open operations from the sidecar.
5. An agent can read open operations without opening a browser.
6. When the source hash matches, the agent can reliably locate every range.
7. When the source hash differs, the tool or agent safely re-anchors only unambiguous feedback and flags the rest.
8. No feedback is silently lost, silently applied to the wrong location, or silently discarded.
9. Generated HTML never becomes the canonical source and is safe to delete.
10. The workflow works entirely on the local machine with Git-tracked Markdown and sidecar files.

## 17. Open decisions before implementation

1. Which Markdown parser and renderer provide reliable inline source positions for the actual document corpus?
2. Should resolved feedback remain in the main sidecar forever, or should the tool archive it after a tagged Git commit?
3. Should reviewers be able to choose between a literal replacement and a higher-level rewrite instruction?
4. How should table-cell and table-row source ranges work when Markdown table parsing normalizes whitespace?
5. Should Richie later support independent SVG element anchors, or should Mermaid source ranges remain the review boundary?
6. Should the tool generate a review HTML file on disk or render dynamically from the Markdown server-side?
7. Should the review application open drafts through a file picker, an OS file association, or drag-and-drop?

## 18. Recommendation

Build this as a narrow Markdown review layer.

The smallest valuable product is source-aware rendered Markdown plus structured suggestions and comments in a committed JSON sidecar. Prove that this reduces review friction on several real documents before adding collaboration, automation, or richer visual features.
