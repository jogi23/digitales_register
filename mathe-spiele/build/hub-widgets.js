  // Einmaleins-Tafel und Zwanzigerfeld: zeigen nacheinander Beispielaufgaben.
  (() => {
    const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const rnd = (a, b) => a + Math.floor(Math.random() * (b - a + 1));
    const table = document.getElementById('table');
    if (table) {
      const cap = document.getElementById('tableCap'), cells = [];
      for (let a = 1; a <= 10; a++) for (let b = 1; b <= 10; b++) { const i = document.createElement('i'); i.textContent = a * b; table.appendChild(i); cells.push({ a, b, el: i }); }
      const show = (a, b) => { cells.forEach(c => { c.el.classList.toggle('row', c.a === a); c.el.classList.toggle('hit', c.a === a && c.b === b); }); cap.innerHTML = `<b>${a} · ${b} = ${a * b}</b>`; };
      show(7, 8);
      if (!reduce) setInterval(() => show(rnd(1, 10), rnd(1, 10)), 2200);
    }
    const field = document.getElementById('field');
    if (field) {
      const cap = document.getElementById('fieldCap'), dots = [];
      for (let k = 0; k < 20; k++) { const i = document.createElement('i'); field.appendChild(i); dots.push(i); }
      const show = (a, b, add) => {
        dots.forEach((d, k) => { d.className = add ? (k < a ? 'a' : k < a + b ? 'b' : '') : (k < a - b ? 'a' : k < a ? 'x' : ''); });
        cap.innerHTML = `<b>${a} ${add ? '+' : '−'} ${b} = ${add ? a + b : a - b}</b>`;
      };
      show(8, 5, true);
      if (!reduce) setInterval(() => { const add = Math.random() < .5; if (add) { const a = rnd(2, 15); show(a, rnd(1, 20 - a), true); } else { const a = rnd(6, 20); show(a, rnd(1, a - 1), false); } }, 2400);
    }
  })();
