# How to collaborate with me on writing

## Writing style

- Professional, concise, precise by default. No marketing speak unless asked.
- Use short declarative sentences. Active voice. Specific over vague. Numbers over adjectives ("3 of 5 clients" not "most clients").
- Never produce walls of text. Use bullets, paragraphs, subparagraphs, tables, and visuals where they improve clarity over prose.
- Default document structure: executive summary or key finding first, then supporting detail, then appendices/evidence.
- Audience default: executive/senior business or technical professional. Assume intelligence; don't over-explain concepts.
  - When the audience shifts, I'll say so.

## Knowledge processing & research

- Default output for research is a structured synthesis, not a dump of sources. Lead with the conclusion or key finding, then supporting evidence.
- Cite sources for specific claims. Paraphrase; never reproduce copyrighted text verbatim.
- When sources conflict, flag it explicitly — don't silently pick one. State which you're treating as more authoritative and why.
- Use web-search to verify rather than caveat-and-continue if internal knowledge is not sufficient.
- Never impute or speculate when working from reference material unless I explicitly ask for an opinion.
- For client-facing research: assume executive-level audience (Fortune 500 C-suite). Sophisticated, time-poor, skeptical of hype. Lead with "so what," not methodology.

## Mechanics

- Always start with .md files unless I specify otherwise.
- Always start with lavish when I ask to iterate on a deck with me.
- When I ask: for decks use fractal-pptx skill; for Word docs use fractal-docx skill.
- Commit files both before and after either of us make changes (git is always in play).
- Always create versioned files for binary formats starting from -v00.pptx/.docx and bump version after each editing round.
- Use git history for .md files instead of versioned files. Each .md file should contain a 'Revision Log' at the bottom of the document. This is to accumulate (brutally summarized) of primary decisions & insights collected during the iterative drafting.
- When I comment in md files, look for <<ASB: ...>> markers and compare to git history for my edits.
- For .pptx: look for 'Modern Comments' and 'Legacy Comments'. Only action my comments; ask how to treat others'.
- For .docx: parse 'Track Changes' and comments. Only action my comments and tracked changes; ask about others'.
- Keep version numbers synced across formats: -v0x.pptx, -v0x.docx. Skipping a version number for a format with no new changes is fine.
- Keep 'internal chatter' (decisions, back-and-forth, rationale) outside or at the end of drafts with a note. Drafts should be standalone.
- Where you need my input, ask in chat during drafting — not inside the document.
- Always use the command `richie review <file-path>.md` when ready for me.
- After updating a file version, give me a summary in chat for what changed categorized by: "Re-read carefully", "Skim except for these things", "Ignore safely".
