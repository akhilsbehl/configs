#!/usr/bin/env node
/** Layout QA: measure every slide in a real browser and fail when content leaves its safe area.
 *  Usage: node check-layout.mjs path/to/deck.html [--only desktop-1366,mobile]
 *  Needs Chrome or Chromium (set BROWSER to a Chromium-family binary to override).
 *  Exit: 0 pass, 1 violations, 2 no usable browser.                                              */
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const args = process.argv.slice(2);
const onlyIdx = args.indexOf('--only');
const only = onlyIdx >= 0 ? args.splice(onlyIdx, 2)[1].split(',') : null;
const jsonOut = args.includes('--json') && args.splice(args.indexOf('--json'), 1).length > 0;
const target = args[0];
if (!target) { console.error('Usage: node check-layout.mjs path/to/deck.html [--only name,name] [--json]'); process.exit(64); }
const file = path.resolve(target), dir = path.dirname(file);
const html = fs.readFileSync(file, 'utf8');

// Margins are fractions of slide WIDTH, so one number is the same distance on every side.
// Engine defaults; a theme overrides via theme.json rules.margins ({"*": {...}, "content": {...}}).
const DEFAULTS = { x: 0.04, top: 0.04, bottom: 0.04, footerGap: 0.015, footerBottom: 0.02 };
const TYPES = ['title', 'closing', 'divider', 'statement', 'bleed', 'agenda', 'content'];
let rules = {};
try { rules = JSON.parse(fs.readFileSync(path.join(dir, 'theme.json'), 'utf8')).rules ?? {}; } catch { /* no theme.json: engine defaults */ }
const floors = { text: rules.minTextPx ?? 12, footer: rules.minFooterPx ?? rules.minTextPx ?? 12 }; // rendered px; themes may lower them
const custom = rules.margins ?? {};
const margins = { '*': { ...DEFAULTS, ...(custom['*'] ?? {}) } };
for (const type of TYPES) margins[type] = { ...margins['*'], ...(custom[type] ?? {}) };

const VIEWPORTS = [
  { name: 'desktop-1728', w: 1728, h: 1000 },   // 1600 px stage
  { name: 'desktop-1366', w: 1366, h: 768 },
  { name: 'desktop-1024', w: 1024, h: 768 },    // type clamps hit their minimums: tightest desktop case
  { name: 'print-1536', w: 1536, h: 864, print: true },
  { name: 'mobile-390', w: 390, h: 844, mobile: true },
];

const candidates = [process.env.BROWSER, 'google-chrome', 'chromium', 'chromium-browser'].filter(Boolean);
const browser = candidates.find(c => { try { return /chrom/i.test(execFileSync(c, ['--version'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] })); } catch { return false; } });
if (!browser) { console.error('SKIPPED: no Chrome or Chromium found. Layout was NOT checked. Install one or set BROWSER.'); process.exit(2); }

const probe = fs.readFileSync(path.join(root, 'engine/layout-probe.js'), 'utf8');
const failures = [];
const budgets = new Map(); // slide -> { type, vps: [{ vp, has, needs, rows }], vertical }
let checked = 0;
const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'html-deck-layout-')); // own profile: a running Chrome would otherwise swallow the headless run
for (const vp of VIEWPORTS.filter(v => !only || only.some(o => v.name.startsWith(o)))) {
  const config = JSON.stringify({ margins, floors, print: !!vp.print, mobile: !!vp.mobile }).replace(/</g, '\\u003c');
  const injected = html.replace(/<\/body>/i, `<script id="qa-config" type="application/json">${config}</script>\n<script>${probe}</script>\n</body>`);
  const temp = path.join(dir, `.layout-check-${process.pid}-${vp.name}.html`);
  fs.writeFileSync(temp, injected);
  try {
    let m = null;
    for (let attempt = 0; attempt < 3 && !m; attempt++) { // headless virtual time occasionally dumps before the probe finishes
      const dom = execFileSync(browser, ['--headless=new', '--no-sandbox', '--disable-gpu', `--user-data-dir=${profile}`, `--window-size=${vp.w},${vp.h}`, `--virtual-time-budget=${8000 + attempt * 6000}`, '--dump-dom', `file://${temp}`],
        { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024, stdio: ['ignore', 'pipe', 'ignore'] });
      m = /<script id="qa-result" type="application\/json">([\s\S]*?)<\/script>/.exec(dom);
    }
    if (!m) { failures.push(`${vp.name}: probe produced no result (page failed to load or script error)`); continue; }
    const results = JSON.parse(m[1]);
    if (results.error) { failures.push(`${vp.name}: probe error: ${results.error.split('\n')[0]}`); continue; }
    checked += results.length;
    for (const r of results) {
      const b = budgets.get(r.slide) ?? { type: r.type, vps: [], vertical: false };
      if (r.budget) b.vps.push({ vp: vp.name, ...r.budget });
      if (r.violations.some(v => ['top', 'bottom', 'footer-gap', 'cut-off'].includes(v.side))) b.vertical = true;
      budgets.set(r.slide, b);
    }
    for (const r of results) for (const v of r.violations) {
      const px = `${v.over}px`;
      const msg = {
        left: `content is ${px} inside the left margin`, right: `content is ${px} past the right margin`, top: `content is ${px} inside the top margin`,
        bottom: `content is ${px} past the bottom margin`, 'footer-gap': `content is ${px} too close to (or over) the footer`,
        'footer-left': `footer text is ${px} inside the left margin`, 'footer-right': `footer text is ${px} past the right margin`, 'footer-bottom': `footer text is ${px} below its bottom margin`,
        'small-text': `text renders at ${v.fs}px, below this theme's ${v.limit}px floor`,
        'cut-off': `content runs ${px} off the bottom of the slide (CUT OFF)`, 'cut-off-x': `content runs ${px} off the right of the slide (CUT OFF)`,
        overlap: `visible text overlaps a logo or image (intersection area ${px}²)`,
      }[v.side];
      failures.push(`slide ${r.slide} (${r.type}) @${vp.name}: ${msg}${v.what ? ` — “${v.what}”` : ''}`);
    }
  } catch (error) {
    failures.push(`${vp.name}: browser failed: ${String(error.message).split('\n')[0]}`);
  } finally { fs.rmSync(temp, { force: true }); }
}
fs.rmSync(profile, { recursive: true, force: true });

// Budget: turn "it overflows" into "how much to remove", using the tightest viewport.
const report = [];
for (const [slide, b] of budgets) {
  if (!b.vertical || !b.vps.length) continue;
  const rows = b.vps.map(v => ({ ...v, over: v.needs - v.has }));
  const worst = rows.reduce((a, c) => (c.over > a.over ? c : a));
  const fits = rows.filter(v => v.over <= 1);
  const line = `slide ${slide} (${b.type}): body box ${worst.has}px, content needs ${worst.needs}px at ${worst.vp} (${Math.max(worst.over, 0)}px over)`;
  const detail = rows.map(v => `${v.vp.replace(/^desktop-|^print-/, m => m)}: ${v.over > 1 ? `over by ${v.over}` : 'fits'} (needs ${v.needs}, has ${v.has})`).join(' · ');
  let advice;
  if (worst.over <= 1) advice = 'Content fits its body box. The failure is spacing around it (footer gap or an element outside the body): check the title length and any content placed outside .body-area.';
  else {
    const pct = Math.round((worst.over / worst.needs) * 100);
    const r = worst.rows;
    advice = `Remove about ${worst.over}px (${pct}% of the content).`
      + (r ? ` The body is ${r.n} equal ${r.kind} rows of about ${r.px}px: drop ${Math.ceil(worst.over / r.px)} row${Math.ceil(worst.over / r.px) > 1 ? 's' : ''} or cut copy so each row shrinks.` : '')
      + (pct <= 8 ? ' Small: tighten gaps or trim a line of copy.' : pct <= 25 ? ' Medium: cut copy or an item.' : ' Large: split the slide or choose a more compact structure.');
    if (fits.length) advice += ` It fits at ${fits.map(v => v.vp).join(', ')}, so the limit is the smaller screens.`;
  }
  report.push({ slide, type: b.type, worst: worst.vp, has: worst.has, needs: worst.needs, over: Math.max(worst.over, 0), viewports: rows, advice, line, detail });
}
if (jsonOut) {
  console.log(JSON.stringify({ file: path.relative(process.cwd(), file), measurements: checked, problems: failures, budget: report.map(({ line, detail, ...r }) => r) }, null, 2));
  process.exit(failures.length ? 1 : 0);
}
for (const r of report) console.error(`BUDGET: ${r.line}\n        ${r.detail}\n        → ${r.advice}`);
for (const f of failures) console.error(`LAYOUT: ${f}`);
console.log(`Layout checked ${path.relative(process.cwd(), file)}: ${checked} slide measurements, ${failures.length} problems.`);
if (failures.length) console.log('Fix by recomposing the slide (fewer items, less copy, a different structure). Do not shrink text below the theme floors.');
process.exit(failures.length ? 1 : 0);
