K.run({
  id: 'zaubertrank', range: '1x1', title: 'Zaubertrank-Küche', hero: ['🧙', '🧪', '🐸'],
  tagline: 'Lies das Rezept, rechne die Menge aus und wirf die richtige Flasche in den Kessel. Bei jedem Treffer verwandelt sich das Tierchen!',
  startLabel: '🧪 Kessel anheizen',
  buttons: false,
  INGR: ['Drachenspucke', 'Krötenschleim', 'Einhornglitzer', 'Mondtau', 'Feenstaub', 'Spinnenbeine', 'Kürbissaft'],
  FORMS: [['🐸', 'Frosch'], ['🦄', 'Einhorn'], ['🐉', 'Drache'], ['🐙', 'Krake'], ['🦖', 'T-Rex'], ['🐧', 'Pinguin'], ['🦩', 'Flamingo'], ['🐌', 'Schnecke'], ['🦆', 'Ente'], ['🤴', 'Prinz'], ['🐷', 'Schwein'], ['🦔', 'Igel'], ['🐝', 'Biene'], ['🦒', 'Giraffe']],
  COLS: ['#ff5ea8', '#42d4f4', '#ffd23f', '#7ed957'],
  prompt: q => 'Welche Flasche passt zum Rezept?',
  say: q => `${q.a} mal ${q.b} Tropfen`,
  setup(scene, K) {
    this.form = 0;
    scene.innerHTML = `<div class="kitchen" id="kit"><div class="shelf"><div class="jars"><span>🫙</span><span>🕯️</span><span>💀</span><span>🍄</span><span>🕸️</span></div></div>
      <div class="recipe" id="recipe"></div><div class="bottles" id="bottles"></div>
      <div class="wizard" id="wiz">🧙</div>
      <div class="cauldron" id="caul"><div class="pot"></div><div class="brew"></div><i class="bub" style="left:40px"></i><i class="bub" style="left:80px;animation-delay:-.6s"></i><i class="bub" style="left:60px;animation-delay:-1.1s"></i></div>
      <div class="pedestal"></div><div class="creature"><span class="c" id="cre">🐸</span><div class="n" id="cname">Frosch</div></div></div>`;
    K.scene.addEventListener('click', e => { const b = e.target.closest('.bottle'); if (b && !b.classList.contains('used')) K.answer(+b.dataset.v, b); });
  },
  targets: K => [...document.querySelectorAll('.bottle')],
  present(q, K) {
    K.$('#recipe').innerHTML = `<small>Rezept: ${q.a} · ${q.b} Tropfen ${K.pick(this.INGR)}</small><b>${q.a} · ${q.b} = ?</b>`;
    K.$('#bottles').innerHTML = q.choices.map((c, i) => `<button class="bottle" data-v="${c}" style="--col:${this.COLS[i]}" aria-label="${c}"><span class="neck"></span><span class="body"><span>${c}</span></span></button>`).join('');
  },
  puffs(x, y, col, n = 6) {
    const kit = K.$('#kit');
    for (let i = 0; i < n; i++) { const p = document.createElement('div'); p.className = 'puff'; p.style.left = (x - 25 + K.rnd(-20, 20)) + 'px'; p.style.top = (y - 25 + K.rnd(-10, 10)) + 'px'; p.style.setProperty('--pc', col); p.style.setProperty('--px', K.rnd(-50, 50) + 'px'); kit.appendChild(p); K.later(() => p.remove(), 1000); }
  },
  correct(q, el, first, K) {
    const kit = K.$('#kit').getBoundingClientRect(), b = el.getBoundingClientRect(), c = K.$('#caul').getBoundingClientRect();
    const col = el.style.getPropertyValue('--col');
    const dx = c.left + c.width / 2 - (b.left + b.width / 2), dy = c.top + 20 - (b.top + b.height / 2);
    el.style.zIndex = 9;
    el.animate([{ transform: 'translate(0,0) rotate(0)' }, { transform: `translate(${dx / 2}px, ${dy / 2 - 60}px) rotate(160deg)` }, { transform: `translate(${dx}px, ${dy}px) rotate(200deg) scale(.4)`, opacity: 0 }], { duration: 650, easing: 'ease-in', fill: 'forwards' });
    K.later(() => {
      K.sfx.splash(); K.sfx.tone(300, 0, .4, 'sine', .15, 900);
      K.$('#caul').style.setProperty('--brew', col);
      this.puffs(c.left - kit.left + c.width / 2, c.top - kit.top, col, 5);
    }, 650);
    K.later(() => {
      const cre = K.$('#cre'), r = cre.getBoundingClientRect();
      this.puffs(r.left - kit.left + r.width / 2, r.top - kit.top + r.height / 2, '#fff', 7);
      this.form = (this.form + 1) % this.FORMS.length;
      const [e, n] = this.FORMS[this.form];
      cre.textContent = e; cre.classList.remove('morph'); void cre.offsetWidth; cre.classList.add('morph');
      K.$('#cname').textContent = n;
      K.sfx.tone(1200, 0, .5, 'triangle', .1, 2400);
      K.bubble(K.$('#kit'), `Simsalabim! Ein${n === 'Schnecke' || n === 'Ente' || n === 'Biene' || n === 'Giraffe' ? 'e' : ''} ${n}!`, 'auto', '58%', 1300).style.right = '8px';
    }, 1150);
    return 2200;
  },
  wrong(q, v, el, K) {
    el.classList.add('used');
    const kit = K.$('#kit').getBoundingClientRect(), c = K.$('#caul').getBoundingClientRect();
    this.puffs(c.left - kit.left + c.width / 2, c.top - kit.top, '#9b59ff', 8);
    K.sfx.noise(0, .6, .5, 600); K.sfx.tone(200, 0, .5, 'sawtooth', .07, 80);
    const w = K.$('#wiz'); w.insertAdjacentHTML('beforeend', '<span class="soot">💨</span>');
    K.bubble(K.$('#kit'), K.pick(['Puff! Falsche Zutat!', 'Hust, hust!', 'Oje, meine Brille!']), '10px', '52%', 1400);
    K.later(() => { const s = w.querySelector('.soot'); if (s) s.remove(); }, 1300);
  },
  highlight(q) { const b = [...document.querySelectorAll('.bottle')].find(x => +x.dataset.v === q.correct); if (b) b.classList.add('hint-glow'); },
  endText() { return `Am Ende war dein Tierchen ein${['Schnecke', 'Ente', 'Biene', 'Giraffe'].includes(this.FORMS[this.form][1]) ? 'e' : ''} ${this.FORMS[this.form][1]}!`; },
  endEmoji: s => ['🧪', '🧙', '🦄'][s - 1]
});
