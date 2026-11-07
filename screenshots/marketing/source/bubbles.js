// Deterministic fizz so re-renders match.
function fizz(count, w, h, minR, maxR, avoid) {
  let seed = 7;
  const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
  const box = document.querySelector('.bubbles');
  for (let i = 0; i < count; i++) {
    const r = minR + Math.pow(rnd(), 2.2) * (maxR - minR);
    const x = rnd() * w, y = rnd() * h;
    if (avoid && x > avoid[0] && x < avoid[2] && y > avoid[1] && y < avoid[3] && r > minR * 2) continue;
    const b = document.createElement('div');
    b.className = 'bubble';
    Object.assign(b.style, { left: (x - r) + 'px', top: (y - r) + 'px', width: 2 * r + 'px', height: 2 * r + 'px', opacity: (0.35 + rnd() * 0.65).toFixed(2) });
    box.appendChild(b);
  }
}
