#!/usr/bin/env node
/** Scaffold a standalone deck: engine + theme + resolved slots. No runtime dependency. */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const args = process.argv.slice(2);
const opt = name => { const i = args.indexOf(`--${name}`); if (i < 0) return undefined; const [, v] = args.splice(i, 2); return v; };
const themeArg = opt('theme') ?? 'default', modeArg = opt('mode'), client = opt('client') ?? 'Client', title = opt('title') ?? 'Presentation deck';
if (args.includes('--list')) { console.log(fs.readdirSync(path.join(root, 'themes')).join('\n')); process.exit(0); }
const dest = args[0];
if (!dest || args.length !== 1) { console.error('Usage: new-deck.sh DEST [--theme NAME|PATH] [--mode light|dark] [--client TEXT] [--title TEXT]\n       new-deck.sh --list'); process.exit(64); }
const die = message => { console.error(message); process.exit(1); };

const themeDir = fs.existsSync(path.join(root, 'themes', themeArg)) ? path.join(root, 'themes', themeArg) : path.resolve(themeArg);
const manifestPath = path.join(themeDir, 'theme.json'), cssPath = path.join(themeDir, 'theme.css');
if (!fs.existsSync(manifestPath) || !fs.existsSync(cssPath)) die(`Not a theme folder (needs theme.json and theme.css): ${themeDir}`);
const theme = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const modes = theme.modes ?? ['light'];
const mode = modeArg ?? theme.defaultMode ?? modes[0];
if (!modes.includes(mode)) die(`Theme "${theme.name}" does not support mode "${mode}" (supports: ${modes.join(', ')})`);
if (fs.existsSync(dest)) die(`Refusing to overwrite existing path: ${dest}`);

const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');
const fill = s => s.replaceAll('{{client}}', client).replaceAll('{{date}}', new Date().toISOString().slice(0, 10));

const logoHtml = (() => {
  const logo = theme.logo ?? { kind: 'none' };
  if (logo.kind === 'none') return null;
  if (logo.kind === 'image') {
    const label = esc(logo.label ?? theme.name);
    const img = (cls, src) => src ? `<img class="${cls}" src="${esc(src)}" alt="" aria-hidden="true">` : '';
    const light = logo.light ?? logo.dark, dark = logo.dark ?? logo.light;
    return `<span class="logo" data-slot="logo" role="img" aria-label="${label}">${img('logo__light', light)}${img('logo__dark', dark)}</span>`;
  }
  if (logo.kind === 'text') {
    const lang = logo.lang ? ` lang="${esc(logo.lang)}"` : '';
    const caption = logo.caption ? `<span class="logo__caption">${esc(logo.caption)}</span>` : '';
    return `<span class="logo logo--text" data-slot="logo"${lang} role="img" aria-label="${esc(logo.label ?? logo.caption ?? logo.text)}"><span class="logo__mark" aria-hidden="true">${esc(logo.text)}</span>${caption}</span>`;
  }
  die(`Unknown logo kind: ${logo.kind}`);
})();

let html = fs.readFileSync(path.join(root, 'templates/deck.html'), 'utf8');
html = html.replaceAll('<span class="logo" data-slot="logo"></span>', logoHtml ?? '');
html = html.replace(/<img class="motif motif--(\w+)" data-slot="motif:\1" alt="" aria-hidden="true">\n?\s*/g, (full, type) => {
  const src = theme.motifs?.[type];
  return src ? `<img class="motif motif--${type}" data-slot="motif:${type}" src="${esc(src)}" alt="" aria-hidden="true">\n      ` : '';
});
html = html.replaceAll('<span data-slot="footer"></span>', `<span data-slot="footer">${esc(fill(theme.footer ?? ''))}</span>`);
const subs = {
  MODE: mode, DECK_TITLE: esc(title), THEME_NAME: theme.name,
  ENGINE_CSS: fs.readFileSync(path.join(root, 'engine/base.css'), 'utf8').trimEnd(),
  THEME_CSS: fs.readFileSync(cssPath, 'utf8').trimEnd(),
  ENGINE_JS: fs.readFileSync(path.join(root, 'engine/deck.js'), 'utf8').trimEnd(),
};
// Replace in one pass so CSS or JS text containing "{{...}}" is never re-expanded.
html = html.replace(/\{\{(MODE|DECK_TITLE|THEME_NAME|ENGINE_CSS|THEME_CSS|ENGINE_JS)\}\}/g, (_, key) => subs[key]);

fs.mkdirSync(dest, { recursive: true });
fs.writeFileSync(path.join(dest, 'deck.html'), html);
fs.copyFileSync(manifestPath, path.join(dest, 'theme.json'));
const assets = path.join(themeDir, 'assets');
if (fs.existsSync(assets)) fs.cpSync(assets, path.join(dest, 'assets'), { recursive: true });
else fs.mkdirSync(path.join(dest, 'assets'));
console.log(`Created ${dest}/deck.html (theme: ${theme.name}, mode: ${mode})`);
