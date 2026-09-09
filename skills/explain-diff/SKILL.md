---
name: explain-diff
description: Create a self-contained interactive HTML explanation of a code change (diff/branch/PR) saved as a dated file outside the repository.
---
# Explain Diff HTML

Produce a single long-form HTML file explaining a code change. Make it accessible to beginners while providing a concise technical path for experienced engineers.

## Workflow
1. **Scope:** Determine the change via context (checkout, diff, PR). State any necessary assumptions.
2. **Explore:** Trace old/new paths, tests, models, and callers. Base details on checked-in code.
3. **Narrate:** Structure: problem context → old behavior → new mental model → implementation → trade-offs/edge cases.
4. **Build:** Generate one self-contained HTML file (inline CSS/JS, zero external dependencies/CDNs). Save at `/tmp/YYYY-MM-DD-explanation-<slug>.html`.
5. **Validate:** Verify complete HTML, local functionality, pre-formatted code styling, offline interactive quiz logic, and accessibility before handoff.

## Required Page Structure (Single Continuous Page)
- **Title, Summary, & TOC** linking to sections in exact order:
1. **Background:** System context, beginner mental model, components, prior behavior.
2. **Intuition:** Core concept via small concrete inputs/outputs and before/after comparisons.
3. **Code:** Conceptual walkthrough ordered by execution/dependency flow with file/line references.
4. **Quiz:** Exactly 5 interactive, offline multiple-choice questions.

## Diagrams & Examples
- Use semantic HTML/CSS for diagrams (flowcharts, before/after panels, component cards, mapping tables).
- **Forbidden:** ASCII art, ornamental graphics, external images.
- Label arrows, provide concrete example values, and include accessible text captions.

## Quiz Design Rules
- **Count & Position:** Exactly 5 questions. Randomize/shuffle correct answer positions independently across questions; balance position distribution (A–D).
- **Option Quality:** Equal length, grammar, and tone across options. No length cues, joke options, trivia, "all/none of the above," or phrases copied verbatim from text. Distractors must reflect plausible misconceptions.
- **Interactivity & Secrecy:** Evaluate offline in JS upon selection. Show immediate feedback explaining why the answer is correct and why distractors are wrong. Never expose answers in DOM attributes (`title`, `aria-label`), classes, or CSS before selection.

## Technical & Code-Block Constraints
- **Self-Contained:** 100% offline, zero external fonts/CDNs/scripts.
- **Code Rendering:** Enclose code in `<pre><code>...</code></pre>`. Set CSS `white-space: pre` or `white-space: pre-wrap`. Escape HTML/JS characters and preserve whitespace.
- **Accessibility & CSS:** Responsive, visible focus states, WCAG contrast compliance, no reliance on color alone.

## Handoff
Open the html file using $BROWSER. State inspected source targets, core assumptions, and validation results.
