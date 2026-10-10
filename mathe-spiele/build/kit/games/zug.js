K.run({
  id: 'zahlenZug', range: '20', title: 'Zahlen-Zug', hero: ['🚂', '🐄', '🎹'],
  tagline: 'Der Zug braucht Wagen! Tippe auf den Wagen mit der richtigen Zahl – dann wird er angekoppelt. Was da wohl alles mitfährt?',
  startLabel: '🚂 Tuut tuut, los!',
  buttons: false,
  CARGO: [['🐄', 'Muuuh!'], ['🍮', 'Wackel-wackel!'], ['🎹', 'Pling-plong!'], ['🦒', 'Ich pass kaum rein!'], ['🍕', 'Lecker!'], ['🐧', 'Brrr, kalt hier!'], ['🎈', 'Ich fliege gleich weg!'], ['🛁', 'Blubb!'], ['🌵', 'Pieks!'], ['🤡', 'Hupe hupe!'], ['🐘', 'Törööö!'], ['🍉', 'Saftig!'], ['🎁', 'Was ist da drin?'], ['🐷', 'Oink!']],
  COLS: ['#e53935', '#4fb6f0', '#ffb04d', '#8a5cf5'],
  prompt: q => 'Welcher Wagen passt?',
  setup(scene, K) {
    this.n = 0;
    scene.innerHTML = `<div class="land" id="land"><span class="sun">☀️</span><div class="rail side"></div><div class="rail main"></div><div class="sign" id="sign"></div><div class="yard" id="yard"></div><div class="train" id="train"><span class="loco">🚂</span></div></div>`;
    K.scene.addEventListener('click', e => { const w = e.target.closest('.yard .wagon'); if (w && !w.classList.contains('used')) K.answer(+w.dataset.v, w); });
  },
  targets: K => [...document.querySelectorAll('.yard .wagon')],
  wagon(v, i, c) { return `<div class="wagon" data-v="${v}" style="--wc:${this.COLS[i % 4]}" data-say="${c[1]}"><span class="cargo">${c[0]}</span><span class="box">${v}</span><span class="wheels"><i></i><i></i></span></div>`; },
  present(q, K) {
    K.$('#sign').innerHTML = `<small>Nächster Wagen:</small>${q.text} = ?`;
    K.$('#yard').innerHTML = q.choices.map((c, i) => this.wagon(c, i, K.pick(this.CARGO))).join('');
  },
  correct(q, el, first, K) {
    const train = K.$('#train'), land = K.$('#land');
    const r = el.getBoundingClientRect(), last = train.lastElementChild.getBoundingClientRect();
    const dx = last.right + 4 - r.left, dy = last.bottom - r.bottom;
    K.sfx.tone(300, 0, .5, 'sine', .08, 200);
    el.animate([{ transform: 'translate(0,0)' }, { transform: `translate(${dx}px, ${dy}px)` }], { duration: 600, easing: 'ease-in-out', fill: 'forwards' }).onfinish = () => {
      el.remove();
      const color = el.style.getPropertyValue('--wc'), cargo = el.querySelector('.cargo').textContent;
      train.insertAdjacentHTML('beforeend', `<div class="wagon new" style="--wc:${color}"><span class="cargo">${cargo}</span><span class="box">${q.correct}</span><span class="wheels"><i></i><i></i></span></div>`);
      K.sfx.thud(); K.sfx.tone(1200, .05, .05, 'square', .05);
      K.bubble(land, el.dataset.say, '40%', '58%', 1100);
      this.n++;
      // Zug nach links schieben, damit der neue Wagen sichtbar bleibt
      const over = train.scrollWidth + 20 - land.clientWidth;
      if (over > 0) train.style.transform = `translateX(${-over}px)`;
    };
    return 1700;
  },
  wrong(q, v, el, K) {
    el.classList.add('used');
    K.sfx.boing();
    K.bubble(K.$('#land'), `${el.dataset.say} … aber ${v} passt nicht!`, '10px', '20px', 1400);
  },
  highlight(q) { const w = [...document.querySelectorAll('.yard .wagon')].find(x => +x.dataset.v === q.correct); if (w) w.classList.add('hint-glow'); },
  beforeEnd(st, done, K) {
    K.$('#yard').innerHTML = '';
    const land = K.$('#land'), train = K.$('#train');
    K.hint('Tuut tuut! Der Zug fährt ab!', 'good');
    K.sfx.tone(587, 0, .5, 'sawtooth', .06); K.sfx.tone(740, 0, .5, 'sawtooth', .06); K.sfx.tone(587, .6, .7, 'sawtooth', .06); K.sfx.tone(740, .6, .7, 'sawtooth', .06);
    for (let i = 0; i < 6; i++) K.later(() => { land.insertAdjacentHTML('beforeend', `<span class="puffs" style="left:${40 + i * 10}px;bottom:120px">💨</span>`); }, i * 250);
    const cur = new DOMMatrix(getComputedStyle(train).transform).m41;
    train.animate([{ transform: `translateX(${cur}px)` }, { transform: `translateX(${-train.scrollWidth - 40}px)` }], { duration: 2600, easing: 'ease-in', fill: 'forwards' });
    K.later(done, 2700);
  },
  endText() { return `Dein Zug hatte ${this.n} Wagen!`; },
  endEmoji: s => ['🚃', '🚂', '🚄'][s - 1]
});
