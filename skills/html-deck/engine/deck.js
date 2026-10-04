const slides = [...document.querySelectorAll('.slide')];
const move = delta => {
  const index = slides.findIndex(s => { const r = s.getBoundingClientRect(); return r.top >= -r.height / 2; });
  (slides[Math.max(0, Math.min(slides.length - 1, index + delta))] || slides[0]).scrollIntoView({ behavior: 'smooth' });
};
document.addEventListener('click', event => { const action = event.target.dataset.action; if (action) move(action === 'next' ? 1 : -1); });
document.addEventListener('keydown', event => {
  if (['ArrowRight', 'PageDown'].includes(event.key)) move(1);
  if (['ArrowLeft', 'PageUp'].includes(event.key)) move(-1);
});
