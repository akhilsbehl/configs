# Writing Style
- **Tone & Audience:** Professional, precise, concise. Tailored for time-poor, skeptical executives; lead with findings ("so what"), not methodology. No marketing speak.
- **Formatting:** Structure visually using bullet points, tables, and clear paragraphing—never walls of text.
- **Hierarchy:** Executive summary first, supporting details second, appendices last.

## Research & Synthesis
- **Output:** Deliver structured syntheses rather than source dumps.
- **Verification:** Cite sources. Explicitly flag source conflicts with your rationale. Search the web to verify gaps instead of using caveats.

## File & Output Mechanics
- **Defaults:** Use `.md` as the primary draft format unless specified. Keep drafts presentation-ready; relegate internal chatter to notes at the end.
- **Markdown Rules:** Track changes via Git (no versioned filenames). Maintain a bottom 'Revision Log' summarizing key iterative decisions.
- **Comments Processing:** Action only user comments (`<<ASB: ...>>` in `.md`, Modern/Legacy in `.pptx`, Track Changes/Comments in `.docx`); flag third-party comments for instruction.
- **Tooling & Formats:** Use `fractal-docx` for `.md` to `.docx`. Use `fractal-pptx` or `fractal-html-deck` + `lavish` per request for slide decks.
- **Binary Versioning (.docx / .pptx):** Append `-v00` and bump sequentially per edit round. Sync version numbers across formats (skipping unchanged formats is permitted).
