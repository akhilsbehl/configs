#!/usr/bin/env bash
# Smoke test: scaffold every theme (or the ones given) in each supported mode, validate, render.
# Usage: qa.sh [THEME_NAME_OR_PATH ...]   Default: all built-in themes.
set -euo pipefail
root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/html-deck-qa.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
themes=("$@"); [ "${#themes[@]}" -gt 0 ] || mapfile -t themes < <(ls "$root/themes")
browser="${BROWSER:-}"
# BROWSER often defaults to xdg-open; only Chromium-family executables accept these flags.
if [ -n "$browser" ] && ! "$browser" --version 2>&1 | grep -Eqi 'chrome|chromium'; then browser=""; fi
if [ -z "$browser" ]; then
  for candidate in google-chrome chromium chromium-browser; do command -v "$candidate" >/dev/null 2>&1 && { browser="$candidate"; break; }; done
fi
for theme in "${themes[@]}"; do
  dir="$root/themes/$theme"; [ -d "$dir" ] || dir="$theme"
  for mode in $(node -e 'const t=JSON.parse(require("fs").readFileSync(process.argv[1]+"/theme.json"));console.log((t.modes||["light"]).join(" "))' "$dir"); do
    name="$(basename "$theme")-$mode"
    "$root/scripts/new-deck.sh" "$tmp/$name" --theme "$theme" --mode "$mode" >/dev/null
    node "$root/scripts/validate-deck.mjs" "$tmp/$name/deck.html"
    if [ -n "$browser" ]; then node "$root/scripts/check-layout.mjs" "$tmp/$name/deck.html"; fi
    if [ -n "$browser" ]; then
      "$browser" --headless=new --no-sandbox --disable-gpu --window-size=1440,900 --screenshot="$tmp/$name-desktop.png" "file://$tmp/$name/deck.html" >/dev/null 2>&1
      "$browser" --headless=new --no-sandbox --disable-gpu --window-size=390,844 --screenshot="$tmp/$name-mobile.png" "file://$tmp/$name/deck.html" >/dev/null 2>&1
      "$browser" --headless=new --no-sandbox --disable-gpu --print-to-pdf="$tmp/$name.pdf" "file://$tmp/$name/deck.html" >/dev/null 2>&1
      test -s "$tmp/$name-desktop.png" && test -s "$tmp/$name-mobile.png" && test -s "$tmp/$name.pdf"
      echo "  $name: desktop, 390px mobile, PDF rendered."
    fi
  done
done
# Self-test: title caps are structural guards, not visual line-count checks.
"$root/scripts/new-deck.sh" "$tmp/title-cap-hero" --theme "${themes[0]}" >/dev/null
python3 - "$tmp/title-cap-hero/deck.html" <<'PY'
from pathlib import Path
p = Path(__import__('sys').argv[1])
s = p.read_text()
s = s.replace('Make the next move matter.', 'One two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen.', 1)
p.write_text(s)
PY
if report="$(node "$root/scripts/validate-deck.mjs" "$tmp/title-cap-hero/deck.html" 2>&1)"; then echo "SELF-TEST FAILED: validator accepted a 16-word hero title" >&2; exit 1; fi
if ! grep -q "maximum is 15" <<<"$report"; then echo "SELF-TEST FAILED: 16-word hero title was rejected without the 15-word cap" >&2; exit 1; fi
"$root/scripts/new-deck.sh" "$tmp/title-cap-content" --theme "${themes[0]}" >/dev/null
python3 - "$tmp/title-cap-content/deck.html" <<'PY'
from pathlib import Path
p = Path(__import__('sys').argv[1])
s = p.read_text()
s = s.replace('State the decision-relevant conclusion here', 'One two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twenty-one twenty-two twenty-three twenty-four twenty-five twenty-six.', 1)
p.write_text(s)
PY
if report="$(node "$root/scripts/validate-deck.mjs" "$tmp/title-cap-content/deck.html" 2>&1)"; then echo "SELF-TEST FAILED: validator accepted a 26-word content title" >&2; exit 1; fi
if ! grep -q "maximum is 25" <<<"$report"; then echo "SELF-TEST FAILED: 26-word content title was rejected without the 25-word cap" >&2; exit 1; fi
echo "  validator self-test: 16-word hero and 26-word content titles rejected."

# Self-test: the layout checker must FAIL on a slide whose content overflows or is covered by an image.
if [ -n "$browser" ]; then
  "$root/scripts/new-deck.sh" "$tmp/overflow" --theme "${themes[0]}" >/dev/null
  perl -0pi -e 's/(<div class="body-area">)/$1<div style="height:3000px"><\/div><p>overflow marker<\/p>/' "$tmp/overflow/deck.html"
  if report="$(node "$root/scripts/check-layout.mjs" "$tmp/overflow/deck.html" 2>&1)"; then echo "SELF-TEST FAILED: check-layout.mjs accepted an overflowing slide" >&2; exit 1; fi
  if ! grep -q "^BUDGET:" <<<"$report"; then echo "SELF-TEST FAILED: overflow was rejected but no BUDGET report was produced" >&2; exit 1; fi
  echo "  layout checker self-test: overflow rejected, budget reported."

  "$root/scripts/new-deck.sh" "$tmp/overlap" --theme "${themes[0]}" >/dev/null
  python3 - "$tmp/overlap/deck.html" <<'PY'
from pathlib import Path
p = Path(__import__('sys').argv[1])
s = p.read_text()
s = s.replace('</head>', '<style data-deck>.qa-overlap { position:absolute; left:20%; top:40%; width:60%; height:20%; }</style></head>', 1)
img = '<img class="qa-overlap" src="data:image/svg+xml,%3Csvg xmlns=\'http://www.w3.org/2000/svg\' width=\'480\' height=\'200\' fill=\'red\'%3E%3Crect width=\'480\' height=\'200\'/%3E%3C/svg%3E" alt="">'
s = s.replace('<section class="slide closing-slide"', '<section class="slide closing-slide"', 1)
s = s.replace('aria-labelledby="closing-title">', 'aria-labelledby="closing-title">' + img, 1)
p.write_text(s)
PY
  if report="$(node "$root/scripts/check-layout.mjs" "$tmp/overlap/deck.html" 2>&1)"; then echo "SELF-TEST FAILED: check-layout.mjs accepted text covered by an image" >&2; exit 1; fi
  if ! grep -q "visible text overlaps a logo or image" <<<"$report"; then echo "SELF-TEST FAILED: overlap was rejected without an overlap report" >&2; exit 1; fi
  echo "  layout checker self-test: text/image overlap rejected."
fi
[ -n "$browser" ] || echo "Browser smoke checks skipped: set BROWSER or install Chrome/Chromium."
echo "QA passed for: ${themes[*]}"
