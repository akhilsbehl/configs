# Theme contract

A theme is a folder:

```
my-theme/
  theme.json     manifest, slots, validator rules
  theme.css      tokens, @font-face, component rules
  assets/        optional: logos, motifs, fonts (copied to <deck>/assets/)
```

`new-deck.sh --theme my-theme` (path) or `--theme default` (built-in name) builds a deck from it.
The engine (`engine/base.css`) is inlined first. `theme.css` is inlined after it and wins.

## theme.css

Asset URLs in `theme.css` are relative to `deck.html` because the CSS is inlined. Write
`url(assets/fonts/x.woff2)`, not `url(fonts/x.woff2)`. Bundle fonts locally. Do not use `@import`.

### Required tokens (on `:root`)

`--accent --bg --surface --card --border --title --body --muted --font`

`--surface` is the page behind slides. `--bg` is the slide ground.

### Optional tokens

| Token | Purpose | Engine default |
|---|---|---|
| `--on-accent`, `--shadow`, `--scrim`, `--on-photo` | text on accent, slide lift, photo gradient, text over photos | derived |
| `--font-title`, `--font-mono` | heading and numeral families | `--font`, system mono |
| `--text-floor` | smallest size of the `--c-*` text scale used inside `.body-area` | `12px` |
| `--footer-clear` | space kept free above the slide bottom on content slides (write `calc(var(--slide-w) * fraction)`) | `calc(var(--slide-w) * .066)` |
| `--agenda-row-extra` | vertical padding a theme adds to each agenda row (lets the agenda fit its box) | `0px` |
| `--hero-color` | colour of `h1` | `--title` |
| `--edge-x`, `--edge-y` | slide padding | fluid 7vw / 5.2vw |
| `--fs-label`, `--fs-label-lg`, `--fs-body`, `--fs-footer`, `--fs-h1`, `--fs-h2`, `--fs-h3`, `--fs-subtitle`, `--fs-desc`, `--fs-agenda`, `--fs-agenda-sub`, `--fs-quote` | type sizes, as `clamp()` | see `engine/base.css` |
| `--heading-weight`, `--subtitle-weight`, `--label-weight`, `--label-track`, `--label-case`, `--heading-track`, `--desc-style` | type character | neutral |

Define `[data-theme="dark"]` overrides if the theme supports a dark mode, and list `"dark"` in `modes`.

### Per-slide grounds

Custom properties are scoped. To give one slide type another ground, override tokens on its class:

```css
.title-slide, .closing-slide { --bg:#14110F; --title:#F7F3EC; --body:#C8C1B7; --muted:#9A9288; }
```

Do not set `--x:var(--y)` aliases on `:root` if a slide scope should change `--y`; `var()` resolves
where it is declared. This is why `--hero-color` has no `:root` default.

### Overrides

A theme may restyle or reposition anything with CSS: pseudo-elements, absolute positioning, grid
changes. The `default` theme moves the title label to the top-left, adds a seam rule under the
title, and puts a vertical kanji mark at top-right using CSS only. Prefer CSS over changing markup.

## theme.json

```json
{
  "name": "my-theme",
  "description": "One line.",
  "modes": ["light", "dark"],
  "defaultMode": "light",
  "footer": "Brand × {{client}} · Confidential",
  "logo": { "kind": "image", "label": "Brand", "light": "assets/logo-dark.png", "dark": "assets/logo-light.png" },
  "motifs": { "title": "assets/sun.png", "agenda": "assets/circle.png", "divider": "assets/vortex.png", "closing": "assets/circle.png" },
  "rules": { "requiredTokens": { "--accent": "#F7A800" }, "logoOnlyOn": ["title", "closing"], "minLabelPx": 12 }
}
```

### Slots

The skeleton has named holes. `new-deck.sh` fills them once, at scaffold time. The output is plain
static HTML and keeps `data-slot` attributes.

| Slot | Filled from | Notes |
|---|---|---|
| `logo` (title, closing) | `logo` | `kind: "image"`: `light` is the file used in light mode, `dark` in dark mode. Both `<img>` tags are written; CSS shows one. `kind: "text"`: `text`, optional `caption`, `lang`, `label`; markup is `.logo__mark` and `.logo__caption`. `kind: "none"`: the element is removed |
| `footer` | `footer` | `{{client}}` and `{{date}}` are replaced. Empty string leaves an empty span, so the page number stays right-aligned |
| `motif:title`, `motif:agenda`, `motif:divider`, `motif:closing` | `motifs.<type>` | A missing key removes that image. Position and opacity belong in `theme.css` (`.motif--title { … }`) |

### Rules read by the validator

| Rule | Default | Meaning |
|---|---|---|
| `requiredTokens` | none | Token values that must appear in `deck.html` |
| `logoOnlyOn` | `["title","closing"]` | Slide types allowed to contain a logo. `[]` for a theme with no logo |
| `minLabelPx` | `12` | Minimum of `--fs-label`. A theme may lower or raise it; the theme's identity wins |
| `minTextPx` | `12` | Smallest rendered text size `check-layout.mjs` accepts |
| `minFooterPx` | `minTextPx` | Smallest rendered footer text. Fractal sets `10` |
| `margins` | see below | Safe-area overrides read by `check-layout.mjs` |

### Safe-area margins (`rules.margins`)

`check-layout.mjs` measures content against a safe area. Values are fractions of the slide **width**, so
one number is the same distance on every side. Engine defaults:

| Key | Default | Meaning |
|---|---|---|
| `x` | `0.04` | Left and right margin for content |
| `top`, `bottom` | `0.04` | Top and bottom margin for content |
| `footerGap` | `0.015` | Minimum space between content and the footer's top edge |
| `footerBottom` | `0.02` | Minimum space between footer text and the slide's bottom edge |

Override for all slides with `"*"` or for one type: `title`, `closing`, `divider`, `statement`, `bleed`, `agenda`, `content`.

```json
"rules": { "margins": { "*": { "x": 0.05 }, "content": { "bottom": 0.06, "footerGap": 0.03 } } }
```

The engine keeps `--footer-clear` (6.6% of slide width) free above the slide bottom on content slides, which satisfies the default `footerGap`. A theme with a tall footer or a heavy edge treatment must raise **both** `footerGap` and `--footer-clear`. The
deck then fails when content crowds the footer, instead of relying on someone noticing it by eye.

## Checklist for a new theme

1. `scripts/qa.sh path/to/theme` passes in every listed mode (it includes the layout check).
2. Contrast: body text 4.5:1, large text 3:1, on every ground the theme defines.
3. Desktop, 390 px mobile, and PDF print all render without overflow.
4. Fonts are local files, with a licence note in `assets/fonts/README.md`.
5. No literal colours in the deck's slide markup.
