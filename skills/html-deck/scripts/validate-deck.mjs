#!/usr/bin/env node
/** Dependency-free structural guard for html-deck files. Brand rules come from theme.json "rules". */
import fs from 'node:fs';
import path from 'node:path';

const target = process.argv[2];
if (!target) { console.error('Usage: node validate-deck.mjs path/to/deck.html'); process.exit(64); }
const file = path.resolve(target), dir = path.dirname(file);
let html;
try { html = fs.readFileSync(file, 'utf8'); } catch (error) { console.error(`Cannot read ${file}: ${error.message}`); process.exit(1); }
html = html.replace(/<!--[\s\S]*?-->/g, ''); // comments are guidance, not content
const failures = [], warnings = [];
const requireMatch = (pattern, message) => { if (!pattern.test(html)) failures.push(message); };

let theme = null;
const manifest = path.join(dir, 'theme.json');
if (fs.existsSync(manifest)) { try { theme = JSON.parse(fs.readFileSync(manifest, 'utf8')); } catch (e) { failures.push(`theme.json is not valid JSON: ${e.message}`); } }
else warnings.push('no theme.json beside deck.html; theme rules skipped');
const rules = theme?.rules ?? {};
const logoOnlyOn = rules.logoOnlyOn ?? ['title', 'closing'];
const minLabelPx = rules.minLabelPx ?? 12;

requireMatch(/<main\b[^>]*class=["'][^"']*\bdeck\b/, 'missing <main class="deck">');
requireMatch(/class=["'][^"']*\btitle-slide\b/, 'missing title slide');
requireMatch(/class=["'][^"']*\bclosing-slide\b/, 'missing closing slide');
requireMatch(/@media print/, 'missing print stylesheet');
requireMatch(/meta name=["']viewport["']/, 'missing responsive viewport meta tag');
const mode = /<html\b[^>]*data-theme=["']([^"']+)/i.exec(html)?.[1]?.toLowerCase();
if (!['light', 'dark'].includes(mode)) failures.push('html data-theme must be "light" or "dark"');
else if (theme?.modes && !theme.modes.includes(mode)) failures.push(`theme "${theme.name}" does not support mode "${mode}"`);

for (const [token, value] of Object.entries(rules.requiredTokens ?? {})) {
  const escaped = token.replace(/[-]/g, '\\-');
  if (!new RegExp(`${escaped}:\\s*${value.replace(/[#.]/g, '\\$&')}`, 'i').test(html)) failures.push(`theme token ${token} must be ${value}`);
}
const labelDecls = [...html.matchAll(/--fs-label:\s*(?:clamp\(\s*)?(\d+(?:\.\d+)?)px/gi)];
const labelMin = labelDecls.length ? Number(labelDecls.at(-1)[1]) : undefined;
if (labelMin === undefined) failures.push('--fs-label token missing a px minimum');
else if (labelMin < minLabelPx) failures.push(`--fs-label minimum is ${labelMin}px; this theme requires ${minLabelPx}px or larger`);

// A slide runs from its opening tag to the next slide (or </main>), so nested <section> elements are safe.
const opens = [...html.matchAll(/<section\b[^>]*class=["']([^"']*\bslide\b[^"']*)["'][^>]*>/gi)];
const mainEnd = html.search(/<\/main>/i);
const slides = opens.map((m, i) => [m[0], m[1], html.slice(m.index + m[0].length, opens[i + 1]?.index ?? (mainEnd > m.index ? mainEnd : html.length))]);
if (slides.length < 2) failures.push('deck needs at least two <section class="slide"> elements');
const typeOf = classes => /\btitle-slide\b/.test(classes) ? 'title' : /\bclosing-slide\b/.test(classes) ? 'closing' : 'other';
const textOf = markup => markup.replace(/<[^>]+>/g, ' ').replace(/&nbsp;/gi, ' ').replace(/&amp;/gi, '&').replace(/\s+/g, ' ').trim();
const eyebrowText = body => textOf(body.match(/<[^>]*class=["'][^"']*\beyebrow\b[^"']*["'][^>]*>[\s\S]*?<\/[^>]+>/i)?.[0] ?? '');
const numberIn = value => { const m = String(value).match(/(?:^|[^0-9])0*(\d+)(?:[^0-9]|$)/); return m ? Number(m[1]) : null; };
const containsClass = (markup, target, ancestor) => {
  const stack = [], voids = new Set(['area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'param', 'source', 'track', 'wbr']);
  for (const token of markup.matchAll(/<\/?([a-z][\w:-]*)([^>]*)>/gi)) {
    const closing = token[0].startsWith('</'), tag = token[1].toLowerCase();
    if (closing) { while (stack.length && stack.pop().tag !== tag); continue; }
    const attrs = token[2], classes = attrs.match(/class=["']([^"']*)["']/i)?.[1] ?? '';
    if (new RegExp(`(?:^|\\s)${target}(?:\\s|$)`, 'i').test(classes) && stack.some(x => new RegExp(`(?:^|\\s)${ancestor}(?:\\s|$)`, 'i').test(x.classes))) return true;
    if (!voids.has(tag) && !token[0].endsWith('/>')) stack.push({ tag, classes });
  }
  return false;
};
for (const [index, match] of slides.entries()) {
  const classes = match[1], body = match[2], n = index + 1;
  if (!/\bdivider\b/.test(classes) && !/<footer\b[^>]*class=["'][^"']*\bfooter\b/.test(body)) warnings.push(`slide ${n} has no footer (allowed for section dividers only)`);
  if (/\b(content-slide|statement-slide|bleed-slide)\b/.test(classes) && !/<footer[\s\S]*?<span>\s*\d+\s*<\/span>/i.test(body)) warnings.push(`slide ${n} has no numeric page marker`);
  if (!logoOnlyOn.includes(typeOf(classes)) && /class=["'][^"']*\blogo\b/.test(body)) failures.push(`slide ${n} contains a logo; this theme allows logos only on: ${logoOnlyOn.join(', ')}`);
  if (['title', 'closing'].includes(typeOf(classes)) && /class=["'][^"']*\blogo\b/.test(body) && !containsClass(body, 'logo', 'content')) failures.push(`slide ${n} ${typeOf(classes)} logo must be inside .content`);
  if (/data-placeholder=/.test(body)) warnings.push(`slide ${n} still has a placeholder; replace it or delete the slide`);
  if (/\bstyle=["'][^"']*(#[0-9a-f]{3,8}\b|rgba?\()/i.test(body)) warnings.push(`slide ${n} has a literal colour in style=; use theme tokens`);
}

// Keep titles scannable: hero titles and section dividers get a tighter cap than content titles.
const words = value => (textOf(value).match(/[A-Za-z0-9]+(?:['’][A-Za-z0-9]+)?/g) ?? []).length;
for (const [index, match] of slides.entries()) {
  const classes = match[1], body = match[2], n = index + 1;
  const titleMarkup = body.match(/<(?:h1|h2)\b[^>]*>[\s\S]*?<\/(?:h1|h2)>/i)?.[0]
    ?? (/\bstatement-slide\b/.test(classes) ? body.match(/class=["'][^"']*\bstatement\b[^"']*["'][^>]*>[\s\S]*?<\/[a-z]+>/i)?.[0] : null);
  if (!titleMarkup) continue;
  const count = words(titleMarkup), hero = /\b(?:title-slide|closing-slide|divider|statement-slide)\b/.test(classes), limit = hero ? 15 : 25;
  if (count > limit) failures.push(`slide ${n} title is ${count} words; maximum is ${limit} for ${hero ? 'hero or divider' : 'content'} titles`);
}

// Section structure: agenda items map 1:1 to numbered dividers, and content keeps the
// current section number in its eyebrow (for example, "02 · Transmission").
const agenda = slides.find(([, classes]) => /\bagenda-slide\b/.test(classes));
const agendaCount = agenda ? (agenda[2].match(/<li\b/gi) ?? []).length : 0;
const dividerNumbers = [];
let currentSection = null;
for (const [index, match] of slides.entries()) {
  const classes = match[1], body = match[2], n = index + 1;
  if (/\bdivider\b/.test(classes)) {
    const number = numberIn(eyebrowText(body));
    if (number === null) warnings.push(`slide ${n} divider eyebrow has no section number`);
    else dividerNumbers.push(number);
    currentSection = number;
  }
  if (/\b(?:content-slide|statement-slide|bleed-slide)\b/.test(classes) && !/\bagenda-slide\b/.test(classes)) {
    const number = numberIn(eyebrowText(body));
    if (number === null) warnings.push(`slide ${n} eyebrow is missing section numbering (expected ${currentSection === null ? 'a section' : String(currentSection).padStart(2, '0')})`);
    else if (currentSection !== null && number !== currentSection) warnings.push(`slide ${n} eyebrow section ${String(number).padStart(2, '0')} skips or differs from current section ${String(currentSection).padStart(2, '0')}`);
  }
}
if (agenda && agendaCount !== dividerNumbers.length) warnings.push(`agenda has ${agendaCount} items but ${dividerNumbers.length} numbered dividers; agenda items must map 1:1 to dividers`);
if (agendaCount && dividerNumbers.some((number, i) => number !== i + 1)) warnings.push(`divider numbering skips; expected 01 through ${String(agendaCount).padStart(2, '0')}`);

if (/\{\{\w+\}\}/.test(html.replace(/<style[\s\S]*?<\/style>|<script[\s\S]*?<\/script>/g, ''))) failures.push('unresolved {{placeholder}} in markup');

const checkLocal = (src, what) => {
  if (/^(https?:|data:|#)/i.test(src)) { if (!src.startsWith('#')) warnings.push(`external or embedded ${what}: ${src.slice(0, 60)}; decks should be self-contained`); return; }
  if (!fs.existsSync(path.resolve(dir, src.split(/[?#]/)[0]))) failures.push(`missing ${what}: ${src}`);
};
for (const match of html.matchAll(/<img\b([^>]*?)>/gi)) {
  const attrs = match[1];
  const src = /\bsrc=["']([^"']+)["']/i.exec(attrs)?.[1];
  const alt = /\balt=["']([^"']*)["']/i.exec(attrs)?.[1];
  if (!src) { failures.push(`image missing src${/data-slot=["']([^"']+)/.exec(attrs) ? ` (slot ${/data-slot=["']([^"']+)/.exec(attrs)[1]})` : ''}`); continue; }
  checkLocal(src, 'image asset');
  if (alt === undefined) failures.push(`image missing alt text: ${src}`);
  if (alt === '' && !/aria-hidden=["']true["']/i.test(attrs)) failures.push(`empty-alt image must be aria-hidden decorative: ${src}`);
}
for (const match of html.matchAll(/url\(\s*(['"]?)([^)'"]+)\1\s*\)/gi)) checkLocal(match[2], 'CSS asset');
if (/@import\b/i.test(html)) warnings.push('CSS @import found; bundle fonts locally with @font-face');
if (/<img[^>]*class=["'][^"']*logo__light/.test(html) && !(/\[data-theme=["']light["']\]\s+\.logo__dark[^}]*display\s*:\s*none/i.test(html) && /\[data-theme=["']dark["']\]\s+\.logo__light[^}]*display\s*:\s*none/i.test(html))) failures.push('theme-aware logo pair lacks its display:none selectors');

for (const message of warnings) console.warn(`WARN: ${message}`);
for (const message of failures) console.error(`ERROR: ${message}`);
console.log(`Checked ${path.relative(process.cwd(), file)}: ${slides.length} slides, ${failures.length} errors, ${warnings.length} warnings.`);
process.exit(failures.length ? 1 : 0);
