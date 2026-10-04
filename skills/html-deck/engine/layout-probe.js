/* QA-only probe. Injected by scripts/check-layout.mjs; never shipped inside a deck.
   Measures every slide's visible content against its safe area and writes JSON to #qa-result. */
(async () => { try {
  const cfg = JSON.parse(document.getElementById('qa-config').textContent);
  if (cfg.print) {
    const s = document.createElement('style');
    s.textContent = '.deck{display:block!important;padding:0!important}.slide{width:100vw!important;height:calc(100vw*9/16)!important;aspect-ratio:auto!important;margin:0!important}';
    document.head.appendChild(s);
  }
  // setTimeout, not requestAnimationFrame: headless virtual time does not reliably fire rAF.
  const wait = ms => new Promise(r => setTimeout(r, ms));
  await Promise.race([document.fonts.ready, wait(3000)]);
  if (document.readyState !== 'complete') await Promise.race([new Promise(r => addEventListener('load', r, { once: true })), wait(3000)]);
  await wait(150);

  const TYPES = [['title-slide', 'title'], ['closing-slide', 'closing'], ['divider', 'divider'], ['statement-slide', 'statement'], ['bleed-slide', 'bleed'], ['agenda-slide', 'agenda'], ['content-slide', 'content']];
  const typeOf = el => (TYPES.find(([c]) => el.classList.contains(c)) ?? [, 'content'])[1];
  const SKIP = '.motif,.scrim,.footer,.controls,[data-qa-ignore]';
  const visible = el => { const cs = getComputedStyle(el); return cs.display !== 'none' && cs.visibility !== 'hidden' && Number(cs.opacity) !== 0; };
  const rects = (el) => {
    const out = [];
    const cs = getComputedStyle(el);
    for (const n of el.childNodes) {
      if (n.nodeType !== 3 || !n.textContent.trim()) continue;
      const r = document.createRange(); r.selectNodeContents(n);
      for (const q of r.getClientRects()) out.push(q);
    }
    if (/^(IMG|SVG|CANVAS|VIDEO)$/i.test(el.tagName)) out.push(el.getBoundingClientRect());
    else if (!el.children.length && !el.textContent.trim()) {
      const hasBg = !/rgba?\(\s*\d+,\s*\d+,\s*\d+,\s*0\s*\)|transparent/.test(cs.backgroundColor) || cs.backgroundImage !== 'none';
      const hasBorder = ['Top', 'Right', 'Bottom', 'Left'].some(s => parseFloat(cs[`border${s}Width`]) > 0 && cs[`border${s}Style`] !== 'none');
      if (hasBg || hasBorder) out.push(el.getBoundingClientRect());
    }
    return out.filter(q => q.width >= 2 && q.height >= 2);
  };
  const label = el => (el.textContent.trim().replace(/\s+/g, ' ').slice(0, 40)) || `<${el.tagName.toLowerCase()}${el.className && typeof el.className === 'string' ? '.' + el.className.split(/\s+/)[0] : ''}>`;
  const overlap = (a, b) => {
    const width = Math.min(a.right, b.right) - Math.max(a.left, b.left);
    const height = Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top);
    return width > 1 && height > 1 ? width * height : 0;
  };
  const textFragments = root => {
    const out = [], walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    let node;
    while (node = walker.nextNode()) {
      if (!node.textContent.trim() || node.parentElement?.closest(SKIP) || !visible(node.parentElement)) continue;
      // Text inside a logo is the logo itself, not an independent text box to compare with it.
      if (node.parentElement?.closest('.logo')) continue;
      const range = document.createRange(); range.selectNodeContents(node);
      for (const q of range.getClientRects()) if (q.width > 1 && q.height > 1) out.push({ rect: q, el: node.parentElement });
    }
    return out;
  };
  const imageTargets = root => [...root.querySelectorAll('.logo, img:not(.motif), svg, canvas, video')]
    .filter(el => visible(el) && !el.closest(SKIP))
    .map(el => ({ rect: el.getBoundingClientRect(), el }))
    .filter(({ rect }) => rect.width > 1 && rect.height > 1);

  const results = [];
  document.querySelectorAll('.slide').forEach((slide, index) => {
    const type = typeOf(slide), m = cfg.margins[type] ?? cfg.margins['*'];
    const sr = slide.getBoundingClientRect(), W = sr.width, tol = 1;
    const footer = slide.querySelector('.footer');
    const fr = footer && visible(footer) ? footer.getBoundingClientRect() : null;
    const worst = {};
    const small = (el, fs, floor) => { if (fs < floor - 0.05 && (!worst.small || fs < worst.small.fs)) worst.small = { side: 'small-text', over: floor - fs, limit: floor, fs: Math.round(fs * 10) / 10, what: label(el) }; };
    const note = (side, over, limit, el) => { if (!worst[side] || over > worst[side].over) worst[side] = { side, over: Math.round(over), limit: Math.round(limit), what: label(el) }; };
    const vertical = !cfg.mobile; // on mobile the slide grows with its content, so only horizontal limits apply
    for (const el of slide.querySelectorAll('*')) {
      if (el.closest(SKIP) || el.classList.contains('bleed') || !visible(el)) continue;
      if ([...el.childNodes].some(n => n.nodeType === 3 && n.textContent.trim())) small(el, parseFloat(getComputedStyle(el).fontSize), cfg.floors.text);
      for (const q of rects(el)) {
        const left = sr.left + m.x * W, right = sr.right - m.x * W, top = sr.top + m.top * W;
        let bottom = sr.bottom - m.bottom * W;
        if (fr) bottom = Math.min(bottom, fr.top - m.footerGap * W);
        if (q.left < left - tol) note('left', left - q.left, left - sr.left, el);
        if (q.right > right + tol) note('right', q.right - right, sr.right - right, el);
        if (vertical && q.top < top - tol) note('top', top - q.top, top - sr.top, el);
        if (q.right > sr.right + tol) note('cut-off-x', q.right - sr.right, 0, el);
        if (vertical && q.bottom > sr.bottom + tol) note('cut-off', q.bottom - sr.bottom, 0, el);
        if (vertical && q.bottom > bottom + tol) note(fr && bottom === fr.top - m.footerGap * W ? 'footer-gap' : 'bottom', q.bottom - bottom, sr.bottom - bottom, el);
      }
    }
    if (footer) for (const el of footer.querySelectorAll('*')) { if ([...el.childNodes].some(n => n.nodeType === 3 && n.textContent.trim())) small(el, parseFloat(getComputedStyle(el).fontSize), cfg.floors.footer); for (const q of rects(el)) {
      if (q.left < sr.left + m.x * W - tol) note('footer-left', sr.left + m.x * W - q.left, m.x * W, el);
      if (q.right > sr.right - m.x * W + tol) note('footer-right', q.right - (sr.right - m.x * W), m.x * W, el);
      if (vertical && q.bottom > sr.bottom - m.footerBottom * W + tol) note('footer-bottom', q.bottom - (sr.bottom - m.footerBottom * W), m.footerBottom * W, el);
    } }
    // Text must not be covered by a logo or content image. Compare individual rendered text
    // fragments so a multi-line title reports the line that is actually obscured.
    for (const text of textFragments(slide)) for (const target of imageTargets(slide)) {
      const area = overlap(text.rect, target.rect);
      if (area > 4) {
        const message = `${label(text.el)} overlaps ${label(target.el)}`;
        if (!worst.overlap || area > worst.overlap.area) worst.overlap = { side: 'overlap', over: Math.round(area), what: message };
      }
    }
    // Budget: the body box's real height against the height its content wants (only where the body is a size container).
    let budget = null;
    const body = slide.querySelector(':scope > .body-area');
    if (body && vertical) {
      const has = body.clientHeight, needs = Math.max(body.scrollHeight, has);
      budget = { has, needs };
      let best = null; // the largest run of equal-height rows, so the report can say "about N rows"
      for (const list of body.querySelectorAll('ol, ul, tbody')) {
        const hs = [...list.children].map(c => c.getBoundingClientRect().height).filter(h => h > 0);
        if (hs.length < 3) continue;
        const mean = hs.reduce((a, b) => a + b, 0) / hs.length;
        if (Math.max(...hs) - Math.min(...hs) > mean * 0.6) continue;
        const total = mean * hs.length;
        if (!best || total > best.total) best = { n: hs.length, px: Math.round(mean), total, kind: (typeof list.className === 'string' && list.className.split(/\s+/)[0]) || list.tagName.toLowerCase() };
      }
      if (best && best.total >= 0.5 * needs) budget.rows = { n: best.n, px: best.px, kind: best.kind };
    }
    results.push({ slide: index + 1, type, width: Math.round(W), budget, violations: Object.values(worst) });
  });
  const out = document.createElement('script');
  out.id = 'qa-result'; out.type = 'application/json';
  out.textContent = JSON.stringify(results).replace(/</g, '\\u003c');
  document.body.appendChild(out);
} catch (error) { const e = document.createElement('script'); e.id = 'qa-result'; e.type = 'application/json'; e.textContent = JSON.stringify({ error: String(error && error.stack || error) }).replace(/</g, '\\u003c'); document.body.appendChild(e); } })();
