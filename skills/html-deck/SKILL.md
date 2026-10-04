---
name: html-deck
description: >
  Create responsive, browser-native HTML presentation decks with swappable themes. Use for
  self-contained HTML slides, presentation microsites, and printable browser decks. Built-in
  themes: default, minimalist. Brand skills (for example fractal-html-deck) supply their own theme.
---

# HTML Deck

Create purposeful decks, not documents poured into web pages. Deliver a self-contained folder
with `deck.html` that opens in a modern browser without a build step.

This skill owns the engine, the slide grammar, the QA tools, and the craft of visual narration.
A **theme** owns everything that looks like a brand: colours, fonts, logo, motifs, footer text.

## Workflow

1. Read `references/visual-narration.md`. It governs every content slide.
2. Choose a theme: a built-in name (`default`, `minimalist`; list with `--list`) or the path of a
   theme folder supplied by a brand skill. If a brand skill invoked you, use its theme and follow
   its extra rules.
3. Scaffold, then edit `deck.html`:

```bash
SKILL_DIR=~/.pi/agent/skills/html-deck   # or this skill's checkout
"$SKILL_DIR/scripts/new-deck.sh" output/my-deck --theme default --client "Acme" --title "Deck title"
node "$SKILL_DIR/scripts/validate-deck.mjs" output/my-deck/deck.html
```

Options: `--theme NAME|PATH`, `--mode light|dark` (if the theme supports it), `--client TEXT`
(fills `{{client}}` in the footer), `--title TEXT`. The script refuses to overwrite an existing path.

The scaffold inlines the engine and theme CSS, resolves the theme's slots (logo, motifs, footer),
and copies the theme's `assets/` and `theme.json` into the folder. Keep every reference relative.

## Slide types

Structure belongs to the engine. Decoration belongs to the theme. Delete unused slides; keep
one title slide and one closing slide.

| Type | Class | Structure |
|---|---|---|
| Title | `title-slide` | Logo slot, eyebrow, hero `h1`, subtitle, description; footer only |
| Agenda | `content-slide agenda-slide` | Eyebrow, numbered `ol.agenda` (optional `<small>` per item); footer and page number |
| Divider | `divider` | Section label, `h2`, optional description; no footer or page number |
| Content | `content-slide` | Assertion-led `h2` plus `.body-area` composed from the evidence; footer and page number |
| Statement | `statement-slide` | One sentence in `blockquote.statement`, optional `.attribution`; footer and page number |
| Full-bleed | `bleed-slide` | Photograph (`img.bleed`), scrim, eyebrow, `h2`; footer and page number |
| Closing | `closing-slide` | Logo slot, `h1`, description; footer only |

Title length is part of the structural QA contract: hero titles (title, closing, statement) and
section-divider `h2` titles are at most **15 words**; other individual slide `h2` titles are at
most **25 words**. `validate-deck.mjs` counts words in the rendered title markup and rejects
breaches. This is a copy guard, not a line-count or font-size rule; use the wider hero container
for sensible wrapping.

Rules that hold in every theme:

- Use semantic `<main class="deck">` with one `<section class="slide">` per slide.
- Style content with theme tokens only: `var(--accent)`, `var(--title)`, `var(--border)`, and so on. Never write literal colours or fonts in slide markup.
- Use semantic lists and tables. Tables need `<th scope="col">` and comfortable padding.
- Give informative images concise alt text. Decorative images use `alt="" aria-hidden="true"`.
- Copy any user-selected or generated image into the deck folder. Save its final generation prompt beside it, for example `assets/hero.prompt.txt`.
- Replace the full-bleed placeholder with a real `<img class="bleed" alt="…">`, or delete the slide.
- Do not add a framework, bundler, CDN, remote font, or remote asset. JavaScript is only for a concrete interaction; content must work without it.

## Web adaptation

Keep the 16:9 desktop stage, fluid type, a single-column reading flow on narrow screens (slides at
least one viewport tall), 16 × 9 inch print pages, and keyboard navigation (arrows, PageUp/PageDown).
Font availability changes line breaks: review desktop, mobile, and print instead of compensating
with fixed positioning.

## Fitting content to the slide

Every `.body-area` is a size container: it knows the real room left after the title and footer.
Build components that scale to it instead of to the viewport.

- `--u` is one unit (about 14 px on a 1600 px stage): 1% of the body width, capped by body height.
  Use it for padding, gaps, bar thickness, and so on: `padding:calc(var(--u) * .6)`.
- `--c-sm`, `--c-md`, `--c-lg`, `--c-xl` are text sizes in units with a floor (`--text-floor`, 12 px by
  default; a theme may change it). Use them inside `.body-area` instead of `vw`-based sizes.
- Fill the box: put `fit` on the body area and `grow` on the main component, or give the component
  `height:100%` and share rows with `grid-template-rows:repeat(var(--n), minmax(min-content, 1fr))`.
  Never use `min-height:0` on rows or `overflow:hidden` on the body; they hide overflow from the checker.
- On narrow screens the body stops being a size container (slides grow with content), `--u` becomes a
  width unit, and `100%` heights fall back to auto.
- Agenda: set `style="--n:6"` on the `ol` if it has other than five items. Agenda items map 1:1 to
  numbered section dividers (`01` … `NN`), and every content, statement, or full-bleed slide carries
  its section number in the eyebrow.

If content still does not fit at the floors, the slide has too much on it. Recompose it.

## Authoring notes

- Put deck-specific CSS in one `<style data-deck>` block after the theme style. Use theme tokens and the `--u`/`--c-*` units only; that keeps the deck correct in every theme.
- Write slide content once and scaffold per theme when a deck must exist in several themes. Do not hand-edit the scaffolded theme CSS.
- Proportional charts (timelines, ranges): generate positions from the axis in a script. Do not place percentages by hand.
- Lay out repeated rows as `grid-template-rows:repeat(var(--n), minmax(min-content, 1fr))` so they share the box evenly and never collapse below their text.
- Give every component a `@media (max-width:700px)` fallback: stack columns, drop secondary glosses, release fixed heights.
- Never carry meaning by colour alone. Pair lanes or series with a group label or direct label.
- A quotation needs its source. Mark translations "paraphrased" unless verified. State approximate dates once in a source note, not in every label.
- Tokens: do not alias one token to another on `:root` (`--a:var(--b)`) if a slide scope should change `--b`; `var()` resolves where it is declared.
- Container units (`cqw`, `cqh`) measure a container's content box. For slide-relative sizes use `--slide-w`.
- Iterate with `check-layout.mjs --only desktop-1024` (the tightest desktop case), then run the full check.
- To look at slides, screenshot headless Chrome at 1728 px wide: each slide is then 1600 × 900, at y = 64 + 964 × (n − 1).

## Themes

A theme is a folder: `theme.json`, `theme.css`, optional `assets/`. See `references/theme-contract.md`
for the tokens, slots, and rules. Themes may override any engine rule, including type-size floors,
through `theme.json` `rules`. The theme's identity wins over engine defaults; keep accessibility
(contrast, keyboard use, alt text) intact regardless.

To create a theme: copy `themes/minimalist` (smallest) or `themes/default`, edit tokens first, then
add component rules. Test with `scripts/qa.sh path/to/theme`.

## QA

Two checks. Run both after each meaningful edit and before delivery. Both must pass.

```bash
node "$SKILL_DIR/scripts/validate-deck.mjs" output/my-deck/deck.html   # structure, tokens, assets, a11y, logo rules
node "$SKILL_DIR/scripts/check-layout.mjs"  output/my-deck/deck.html   # measured in Chrome: margins, footer gap, cut-off
"$SKILL_DIR/scripts/qa.sh"                  # regression: scaffolds and renders every built-in theme, self-tests the checker
"$SKILL_DIR/scripts/qa.sh" /path/to/theme   # same, for an external theme
```

**`validate-deck.mjs`** reads `theme.json` `rules`. It checks structure, required tokens, label-size
floor, asset paths, alt treatment, logo placement, theme-aware logo pair, print CSS, footers, page
markers, leftover placeholders, and literal colours in markup. It reads the file; it cannot see layout.

**`check-layout.mjs`** renders the deck in headless Chrome at five viewports (1728, 1366 and 1024 px
desktop; a 16:9 print emulation; 390 px mobile) and measures every visible text node, image, and
drawn box against the slide's **safe area**. It reports content that is too close to an edge, too close
to or over the footer, visible text covered by a logo or image, text rendered below the theme's size floor, or off the slide (cut off). A deck that looks fine on your screen can still fail
at 1024 px, where type hits its minimum sizes while the stage shrinks. If no browser is found it exits
2 and says layout was **not** checked; treat that as a failure, not a pass.

Text floor: rendered text must be at least `rules.minTextPx` (12 px) and footer text at least
`rules.minFooterPx` (defaults to the text floor). A theme may lower them in `theme.json`; it then owns the call.

Safe area, as a fraction of slide width (so the same distance on every side): 4% left, right, top;
4% bottom; a 1.5% gap between content and the footer; footer text 4% from the sides and 2% from the
bottom. A theme overrides these per slide type in `theme.json` (`rules.margins`, see
`references/theme-contract.md`). Decorative motifs, the full-bleed photograph, and the scrim are exempt.

### Correcting a failed layout check

The report is written for you to act on. For each slide that is too tall it adds a `BUDGET` block:

```
BUDGET: slide 11 (content): body box 329px, content needs 353px at desktop-1024 (24px over)
        desktop-1728: fits (...) · desktop-1024: over by 24 (needs 353, has 329)
        → Remove about 24px (7% of the content). The body is 8 equal reading rows of about 44px: drop 1 row ...
```

1. Fix the slide with the largest `over`, at the viewport it names. Tight screens bind first; a slide that fits at 1728 can still fail at 1024.
2. Size the fix by the advice: about 8% or less, tighten gaps or trim a line; up to about 25%, cut copy or an item (or drop the rows it names); above that, split the slide or pick a more compact structure.
3. Re-run the check. Repeat until it prints 0 problems. Do not stop after one pass: removing content changes other viewports' numbers.
4. If the block says the content fits but a `LAYOUT` line remains, the problem is outside the body box (a long title, or content placed outside `.body-area`).

`check-layout.mjs ... --json` prints the same problems and budgets as JSON for scripts. `--only desktop-1024` runs one viewport (faster while iterating); run the full check before delivery.

When the layout check fails, recompose the slide: fewer items, less copy, a different structure,
or a smaller component. Do not fix it by shrinking text below the theme's floors or by moving the
footer. If a failure is truly intentional (for example a motif that must bleed), mark that element
`data-qa-ignore`.

Before delivery also verify: the selected theme and mode; one assertion-led takeaway and focal point
per narrative slide; a layout that encodes the actual relationship; no decorative card grid; correct
logo placement; title-word caps; agenda/divider and eyebrow numbering; accessible contrast and non-colour cues;
readable sources; keyboard navigation; print pagination; assets that resolve from the delivered folder.
