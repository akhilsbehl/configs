# Writing style

- Professional, concise, precise by default. No marketing speak unless asked.
- Never produce walls of text. Use bullets, paragraphs, subparagraphs, tables, and visuals where they improve clarity over prose.
- Executive summary or key finding/decision first, then supporting detail, then appendices/evidence.
- Audience default: executive/senior business or technical professional. Sophisticated, time-poor, skeptical of hype. Lead with "so what," not methodology.

## Knowledge processing & research

- Default output for research is a structured synthesis, not a dump of sources.
- Cite sources wherever possible.
- When sources conflict, flag it explicitly. Surface your choice and rationale.
- Use web-search to verify rather than caveat-and-continue if internal knowledge is not sufficient.

## Mechanics

- Always start with .md files unless I specify otherwise.
- When building decks, always start with lavish until we are ready for a PPTX.
- For decks use fractal-pptx skill; for Word docs use fractal-docx skill.
- Always create versioned files for binary formats starting from -v00.pptx/.docx and bump version after each editing round.
- Use git history for .md files instead of versioned files.
- Each .md file should contain a 'Revision Log' at the bottom of the document.
  - Accumulate (brutally summarized) primary decisions & insights collected during the iterative drafting.
- Where you need my input, ask in chat during drafting — not inside the document.
- When I comment in md files, look for <<ASB: ...>> markers.
- For .pptx: look for 'Modern Comments' and 'Legacy Comments'. Only action my comments; ask how to treat others'.
- For .docx: parse 'Track Changes' and comments. Only action my comments and tracked changes; ask about others'.
- Keep version numbers synced across formats: -v0x.pptx, -v0x.docx. Skipping a version number for a format with no new changes is fine.
- Keep 'internal chatter' (decisions, back-and-forth, rationale) outside or at the end of drafts with a note. Drafts should always be standalone & presentation ready.
- Use `richie review <file-path>.md` when ready for me to look at something.
- IMP: After interating on a draft version: summarize in chat categorized by: "Re-read carefully", "Skim except for these things", "Ignore safely".
